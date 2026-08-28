<?php

namespace App\Middleware;

class AuthMiddleware
{
    public static function check()
    {
        return isset($_SESSION['user_id']) && !empty($_SESSION['user_id']);
    }

    public static function user()
    {
        if (!self::check()) {
            return null;
        }

        return [
            'id' => $_SESSION['user_id'] ?? null,
            'name' => $_SESSION['user_name'] ?? null,
            'email' => $_SESSION['user_email'] ?? null,
            'role' => $_SESSION['user_role'] ?? null,
            'gender' => $_SESSION['user_gender'] ?? null,
        ];
    }

    public static function requireAuth()
    {
        if (!self::check()) {
            header('X-Robots-Tag: noindex, nofollow');
            header('Location: /login');
            exit;
        }
    }

    public static function requireGuest()
    {
        if (self::check()) {
            header('Location: /dashboard');
            exit;
        }
    }

    public static function hasRole($role)
    {
        if (!self::check()) {
            return false;
        }

        return $_SESSION['user_role'] === $role;
    }

    public static function hasPermission($permission)
    {
        if (!self::check()) {
            return false;
        }

        // Admin tem todas as permissões
        if ($_SESSION['user_role'] === 'admin') {
            return true;
        }

        // Verificar permissões específicas do usuário
        $userPermissions = $_SESSION['user_permissions'] ?? [];
        return in_array($permission, $userPermissions);
    }

    public static function setUser($user)
    {
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['user_name'] = $user['name'];
        $_SESSION['user_email'] = $user['email'];
        $_SESSION['user_role'] = $user['role'];
        $_SESSION['user_gender'] = $user['gender'] ?? null;
        $_SESSION['user_permissions'] = $user['permissions'] ?? [];
    }

    public static function logout()
    {
        session_unset();
        session_destroy();
        header('Location: /login');
        exit;
    }
}
