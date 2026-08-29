<?php
ob_start();
?>
<style>
    .adv-score-detail-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
        gap: 15px;
        margin-bottom: 25px;
    }
    .adv-score-detail-card {
        background: #111;
        border: 1px solid #222;
        padding: 25px;
        text-align: center;
        border-radius: 8px;
        transition: border-color 0.3s;
    }
    .adv-score-detail-card:hover {
        border-color: #ff0000;
    }
    .adv-score-detail-icon {
        font-size: 36px;
        margin-bottom: 10px;
    }
    .adv-score-detail-label {
        color: #888;
        font-size: 12px;
        text-transform: uppercase;
        letter-spacing: 1px;
    }
    .adv-score-detail-value {
        font-size: 32px;
        font-weight: bold;
        margin-top: 8px;
    }
</style>

<div class="page-header">
    <h2>📈 Meus Scores</h2>
    <a href="/advanced-gamification" class="btn">← Voltar</a>
</div>

<div class="adv-score-detail-grid">
    <div class="adv-score-detail-card" style="border-color: #ff0000;">
        <div class="adv-score-detail-icon">⚡</div>
        <div class="adv-score-detail-label">XP Geral</div>
        <div class="adv-score-detail-value" style="color: #ff0000;"><?= number_format($scores['xp']) ?></div>
    </div>
    <div class="adv-score-detail-card">
        <div class="adv-score-detail-icon">🏍️</div>
        <div class="adv-score-detail-label">Ride Score</div>
        <div class="adv-score-detail-value" style="color: #ccc;"><?= number_format($scores['ride']) ?></div>
    </div>
    <div class="adv-score-detail-card">
        <div class="adv-score-detail-icon">🤝</div>
        <div class="adv-score-detail-label">Community Score</div>
        <div class="adv-score-detail-value" style="color: #ccc;"><?= number_format($scores['community']) ?></div>
    </div>
    <div class="adv-score-detail-card">
        <div class="adv-score-detail-icon">🛡️</div>
        <div class="adv-score-detail-label">Trust Score</div>
        <div class="adv-score-detail-value" style="color: #ccc;"><?= number_format($scores['trust']) ?></div>
    </div>
</div>

<div class="card">
    <h3>📜 Histórico de Pontos Recentes</h3>
    <?php if (count($history) > 0): ?>
        <div class="table-responsive">
            <table>
                <thead>
                    <tr>
                        <th>Tipo</th>
                        <th>Pontos</th>
                        <th>Descrição</th>
                        <th>Referência</th>
                        <th>Data</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($history as $entry): ?>
                        <tr>
                            <td style="color: #ccc;"><?= htmlspecialchars($entry['point_type']) ?></td>
                            <td style="color: <?= $entry['points'] >= 0 ? '#4caf50' : '#ff0000' ?>; font-weight: bold;">
                                <?= $entry['points'] >= 0 ? '+' : '' ?><?= number_format($entry['points']) ?>
                            </td>
                            <td style="color: #888;"><?= htmlspecialchars($entry['description'] ?? '') ?></td>
                            <td style="color: #666; font-size: 12px;">
                                <?php if (!empty($entry['reference_type'])): ?>
                                    <?= htmlspecialchars($entry['reference_type'] ?? '') ?> #<?= htmlspecialchars($entry['reference_id'] ?? '') ?>
                                <?php else: ?>
                                    —
                                <?php endif; ?>
                            </td>
                            <td style="color: #666; font-size: 12px;"><?= date('d/m/Y H:i', strtotime($entry['created_at'])) ?></td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php else: ?>
        <p style="color: #666; text-align: center; padding: 30px;">Nenhum registro de pontos ainda.</p>
    <?php endif; ?>
</div>

<?php
$content = ob_get_clean();
require_once __DIR__ . '/../layouts/main.php';
