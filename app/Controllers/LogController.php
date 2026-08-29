<?php

namespace App\Controllers;

use App\Middleware\AuthMiddleware;
use App\Middleware\CsrfMiddleware;
use App\Services\DatabaseService;

class LogController extends Controller
{
    private $db;

    public function __construct()
    {
        $this->db = DatabaseService::connect();
    }

    public function index()
    {
        AuthMiddleware::requireAuth();
        AuthMiddleware::hasPermission('logs.view');

        $page = $_GET['page'] ?? 1;
        $perPage = 20;
        $offset = ($page - 1) * $perPage;

        // Filtros
        $action = $_GET['action'] ?? '';
        $entityType = $_GET['entity_type'] ?? '';
        $userId = $_GET['user_id'] ?? '';
        $startDate = $_GET['start_date'] ?? '';
        $endDate = $_GET['end_date'] ?? '';

        $where = ['1=1'];
        $params = [];

        if (!empty($action)) {
            $where[] = "action LIKE ?";
            $params[] = "%{$action}%";
        }

        if (!empty($entityType)) {
            $where[] = "entity_type = ?";
            $params[] = $entityType;
        }

        if (!empty($userId)) {
            $where[] = "user_id = ?";
            $params[] = $userId;
        }

        if (!empty($startDate)) {
            $where[] = "created_at >= ?";
            $params[] = $startDate . ' 00:00:00';
        }

        if (!empty($endDate)) {
            $where[] = "created_at <= ?";
            $params[] = $endDate . ' 23:59:59';
        }

        $whereClause = implode(' AND ', $where);

        // Contar total de registros
        $countStmt = $this->db->prepare("SELECT COUNT(*) as total FROM logs WHERE {$whereClause}");
        $countStmt->execute($params);
        $total = $countStmt->fetch()['total'];
        $totalPages = ceil($total / $perPage);

        // Buscar logs com paginação
        $stmt = $this->db->prepare("SELECT l.*, u.name as user_name 
                                     FROM logs l 
                                     LEFT JOIN users u ON l.user_id = u.id 
                                     WHERE {$whereClause} 
                                     ORDER BY l.created_at DESC 
                                     LIMIT {$perPage} OFFSET {$offset}");
        $stmt->execute($params);
        $logs = $stmt->fetchAll();

        // Buscar usuários para filtro
        $usersStmt = $this->db->query("SELECT DISTINCT u.id, u.name FROM logs l JOIN users u ON l.user_id = u.id ORDER BY u.name");
        $users = $usersStmt->fetchAll();

        // Buscar tipos de entidades para filtro
        $entitiesStmt = $this->db->query("SELECT DISTINCT entity_type FROM logs ORDER BY entity_type");
        $entities = $entitiesStmt->fetchAll(\PDO::FETCH_COLUMN);

        // Buscar tipos de ações para filtro
        $actionsStmt = $this->db->query("SELECT DISTINCT action FROM logs ORDER BY action");
        $actions = $actionsStmt->fetchAll(\PDO::FETCH_COLUMN);

        $data = [
            'title' => 'Logs do Sistema - MotoHead',
            'logs' => $logs,
            'users' => $users,
            'entities' => $entities,
            'actions' => $actions,
            'pagination' => [
                'current' => $page,
                'total' => $totalPages,
                'per_page' => $perPage,
                'total_records' => $total
            ],
            'filters' => [
                'action' => $action,
                'entity_type' => $entityType,
                'user_id' => $userId,
                'start_date' => $startDate,
                'end_date' => $endDate
            ],
            'user' => AuthMiddleware::user()
        ];

        $this->view('logs/index', $data);
    }

    public function show($id)
    {
        AuthMiddleware::requireAuth();
        AuthMiddleware::hasPermission('logs.view');

        $stmt = $this->db->prepare("SELECT l.*, u.name as user_name 
                                     FROM logs l 
                                     LEFT JOIN users u ON l.user_id = u.id 
                                     WHERE l.id = ?");
        $stmt->execute([$id]);
        $log = $stmt->fetch();

        if (!$log) {
            header('Location: /logs');
            exit;
        }

        $data = [
            'title' => 'Detalhes do Log - MotoHead',
            'log' => $log,
            'user' => AuthMiddleware::user()
        ];

        $this->view('logs/view', $data);
    }

    public function clear()
    {
        AuthMiddleware::requireAuth();
        AuthMiddleware::hasPermission('logs.delete');

        // Limpar logs antigos (mais de 30 dias)
        $stmt = $this->db->prepare("DELETE FROM logs WHERE created_at < DATE_SUB(NOW(), INTERVAL 30 DAY)");
        $stmt->execute();

        $user = AuthMiddleware::user();
        
        // Registrar limpeza
        $this->logActivity('logs.cleared', 'logs', 0, "Logs antigos limpos por {$user['name']}");

        header('Location: /logs');
        exit;
    }

    private function logActivity($action, $entityType, $entityId, $details)
    {
        $user = AuthMiddleware::user();
        
        $stmt = $this->db->prepare("INSERT INTO logs (user_id, action, entity_type, entity_id, details, ip_address, user_agent, created_at) 
                                    VALUES (?, ?, ?, ?, ?, ?, ?, NOW())");
        $stmt->execute([
            $user['id'],
            $action,
            $entityType,
            $entityId,
            json_encode(['message' => $details]),
            $_SERVER['REMOTE_ADDR'] ?? 'unknown',
            $_SERVER['HTTP_USER_AGENT'] ?? 'unknown'
        ]);
    }

    /// API endpoint para receber logs do app Flutter
    /// POST /api/logs
    public function apiUpload()
    {
        header('Content-Type: application/json');
        
        try {
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!$input) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid JSON']);
                return;
            }

            $appVersion = $input['app_version'] ?? 'unknown';
            $deviceInfo = $input['device_info'] ?? [];
            $logs = $input['logs'] ?? [];

            if (empty($logs)) {
                http_response_code(400);
                echo json_encode(['error' => 'No logs provided']);
                return;
            }

            // Salvar logs em arquivo (storage/logs/flutter/)
            $logDir = __DIR__ . '/../../storage/logs/flutter';
            if (!is_dir($logDir)) {
                mkdir($logDir, 0755, true);
            }

            $timestamp = date('Y-m-d_H-i-s');
            $filename = "flutter_{$timestamp}.txt";
            $filepath = "{$logDir}/{$filename}";

            $logContent = "App Version: {$appVersion}\n";
            $logContent .= "Device: " . json_encode($deviceInfo) . "\n";
            $logContent .= "Logs Count: " . count($logs) . "\n";
            $logContent .= "=== LOGS ===\n";
            $logContent .= implode("\n", $logs);

            file_put_contents($filepath, $logContent);

            http_response_code(200);
            echo json_encode(['success' => true, 'file' => $filename]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
