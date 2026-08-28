<?php
ob_start();
$noindex = true;
?>

<?php use App\Middleware\CsrfMiddleware; ?>

<style>
    .dashboard-grid {
        display: grid;
        grid-template-columns: 1fr 300px;
        gap: 20px;
    }
    .dashboard-events-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 10px;
    }
    .dashboard-invite-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 12px;
        margin-bottom: 20px;
    }
    @media (max-width: 1024px) {
        .dashboard-grid {
            grid-template-columns: 1fr 260px;
            gap: 15px;
        }
    }
    @media (max-width: 768px) {
        .dashboard-grid {
            grid-template-columns: 1fr;
            gap: 15px;
        }
        .dashboard-events-grid {
            grid-template-columns: 1fr;
        }
        .dashboard-invite-grid {
            grid-template-columns: 1fr;
        }
        .dashboard-actions {
            flex-direction: column !important;
        }
        .dashboard-actions a {
            min-width: 100% !important;
        }
        .dashboard-sidebar {
            order: 1;
        }
        .dashboard-main {
            order: 2;
        }
    }
    @media (max-width: 480px) {
        .dashboard-invite-modal {
            padding: 20px !important;
        }
    }
</style>

<div class="dashboard-grid">

    <!-- Coluna principal: Conteudo -->
    <div class="dashboard-main">
        <!-- Card de eventos proximos -->
        <?php if (!$is_admin && !empty($stats['upcoming_events'])): ?>
        <div class="card" style="border-radius: 16px;">
            <h3 style="color: #ccc; border: none; padding: 0; margin: 0 0 15px 0; font-size: 15px;">&#127901; Pr&oacute;ximos Eventos</h3>
            <div class="dashboard-events-grid">
                <?php foreach (array_slice($stats['upcoming_events'], 0, 4) as $event): ?>
                <div style="padding: 10px; background: #1a1a1a; border-left: 3px solid #ffcc00; border-radius: 8px;">
                    <p style="color: #ccc; font-size: 13px; margin-bottom: 3px;"><?= htmlspecialchars($event['title'] ?? $event['name'] ?? 'Evento') ?></p>
                    <p style="color: #666; font-size: 11px;"><?= date('d/m/Y', strtotime($event['event_date'])) ?></p>
                    <p style="color: #555; font-size: 11px;"><?= htmlspecialchars($event['location'] ?? '-') ?></p>
                </div>
                <?php endforeach; ?>
            </div>
        </div>
        <?php endif; ?>

        <!-- Card de boas-vindas / Como funciona a comunidade -->
        <div class="card" style="padding: 0; overflow: hidden; border: 1px solid var(--mc-border); border-radius: 16px;">
            <div style="background: linear-gradient(135deg, var(--mc-primary-dark), var(--mc-primary)); padding: 25px; text-align: center;">
                <div style="font-size: 40px; margin-bottom: 10px;">🏍️</div>
                <h2 style="color: #fff; margin: 0; font-size: 22px; border: none; padding: 0;">Bem-vindo ao MotoHead!</h2>
                <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0; font-size: 14px;">A rede social dos motociclistas brasileiros</p>
            </div>

            <!-- Feed da Comunidade -->
            <div style="padding: 0 25px;">
                <h3 style="color: var(--mc-text); font-size: 16px; margin: 20px 0 10px; border: none; padding: 0;">📰 Feed da Comunidade</h3>
            </div>
            <div id="infinite-feed" style="display: flex; flex-direction: column; gap: 0; padding: 0 25px 20px;"></div>
            <div id="feed-loader" style="text-align: center; padding: 20px; display: none;">
                <span style="color: var(--mc-text-muted); font-size: 13px;">Carregando mais publicações...</span>
            </div>
            <div id="feed-end" style="text-align: center; padding: 10px 20px 20px; display: none;">
                <span style="color: var(--mc-text-muted); font-size: 13px;">Não há mais publicações.</span>
            </div>

            <div style="padding: 25px;">
                <div style="background: rgba(255,204,0,0.1); border: 1px solid rgba(255,204,0,0.3); border-radius: 8px; padding: 15px; margin-bottom: 20px; text-align: center;">
                    <span style="font-size: 24px;">🏆</span>
                    <h3 style="color: #ffcc00; margin: 8px 0 5px; font-size: 16px; border: none; padding: 0;">Você é um Membro Pioneiro!</h3>
                    <p style="color: var(--mc-text-muted); font-size: 13px; margin: 0; line-height: 1.5;">
                        Você está entre os primeiros a acessar e testar todas as funcionalidades da plataforma.
                        Sua participação desde o início garante vantagens exclusivas no futuro.
                    </p>
                </div>

                <h3 style="color: var(--mc-text); font-size: 16px; margin-bottom: 15px; border: none; padding: 0;">📖 Como funciona a comunidade</h3>

                <div style="display: flex; flex-direction: column; gap: 12px; margin-bottom: 20px;">
                    <div style="display: flex; gap: 12px; align-items: flex-start;">
                        <span style="font-size: 22px; flex-shrink: 0;">👥</span>
                        <div>
                            <strong style="color: var(--mc-text); font-size: 14px;">Conecte-se</strong>
                            <p style="color: var(--mc-text-muted); font-size: 13px; margin: 3px 0 0; line-height: 1.5;">Adicione amigos, siga outros motociclistas e participe de grupos. Compartilhe experiências, rotas e histórias.</p>
                        </div>
                    </div>
                    <div style="display: flex; gap: 12px; align-items: flex-start;">
                        <span style="font-size: 22px; flex-shrink: 0;">🗺️</span>
                        <div>
                            <strong style="color: var(--mc-text); font-size: 14px;">Explore Rotas e Eventos</strong>
                            <p style="color: var(--mc-text-muted); font-size: 13px; margin: 3px 0 0; line-height: 1.5;">Descubra novas rotas motociclísticas, participe de eventos, comboios e encontros perto de você.</p>
                        </div>
                    </div>
                    <div style="display: flex; gap: 12px; align-items: flex-start;">
                        <span style="font-size: 22px; flex-shrink: 0;">🔧</span>
                        <div>
                            <strong style="color: var(--mc-text); font-size: 14px;">Gerencie sua Garagem</strong>
                            <p style="color: var(--mc-text-muted); font-size: 13px; margin: 3px 0 0; line-height: 1.5;">Cadastre suas motos, controle manutenções, combustível, gastos e equipamentos em um só lugar.</p>
                        </div>
                    </div>
                    <div style="display: flex; gap: 12px; align-items: flex-start;">
                        <span style="font-size: 22px; flex-shrink: 0;">🏆</span>
                        <div>
                            <strong style="color: var(--mc-text); font-size: 14px;">Ganhe Pontos e Medalhas</strong>
                            <p style="color: var(--mc-text-muted); font-size: 13px; margin: 3px 0 0; line-height: 1.5;">Participe ativamente para acumular XP, subir de nível e desbloquear medalhas exclusivas.</p>
                        </div>
                    </div>
                    <div style="display: flex; gap: 12px; align-items: flex-start;">
                        <span style="font-size: 22px; flex-shrink: 0;">🏠</span>
                        <div>
                            <strong style="color: var(--mc-text); font-size: 14px;">Crie seu Grupo</strong>
                            <p style="color: var(--mc-text-muted); font-size: 13px; margin: 3px 0 0; line-height: 1.5;">Funde um grupo ou clube motociclista, convide membros e organize passeios e reuniões.</p>
                        </div>
                    </div>
                </div>

                <div style="background: var(--mc-bg-hover); border-radius: 8px; padding: 15px; margin-bottom: 20px;">
                    <h3 style="color: var(--mc-text); font-size: 15px; margin: 0 0 10px; border: none; padding: 0;">📱 Aplicativo em breve!</h3>
                    <p style="color: var(--mc-text-muted); font-size: 13px; margin: 0 0 12px; line-height: 1.5;">
                        Em breve será disponibilizado o aplicativo MotoHead para uso em viagens, com rastreamento GPS,
                        navegação por rotas, registro de trajetos e muito mais.
                    </p>
                    <p style="color: var(--mc-text-muted); font-size: 13px; margin: 0; line-height: 1.5;">
                        <strong style="color: var(--mc-primary);">Por enquanto, explore o site à vontade!</strong>
                        Convide seus amigos, crie seu grupo, cadastre suas motos e comece a ganhar pontos.
                    </p>
                </div>

                <div class="dashboard-actions" style="display: flex; gap: 10px; flex-wrap: wrap;">
                    <a href="/feed/create" style="flex: 1; min-width: 120px; text-align: center; padding: 10px; background: var(--mc-primary); color: #fff; border-radius: 6px; text-decoration: none; font-size: 13px; font-weight: 600;">
                        📝 Publicar no Feed
                    </a>
                    <a href="/stories/create" style="flex: 1; min-width: 120px; text-align: center; padding: 10px; background: var(--mc-bg-hover); color: var(--mc-text); border: 1px solid var(--mc-border); border-radius: 6px; text-decoration: none; font-size: 13px; font-weight: 600;">
                        📖 Compartilhar História
                    </a>
                    <a href="/routes/create" style="flex: 1; min-width: 120px; text-align: center; padding: 10px; background: var(--mc-bg-hover); color: var(--mc-text); border: 1px solid var(--mc-border); border-radius: 6px; text-decoration: none; font-size: 13px; font-weight: 600;">
                        🗺️ Criar Rota
                    </a>
                </div>

                <div style="margin-top: 15px; padding-top: 15px; border-top: 1px solid var(--mc-border); text-align: center;">
                    <p style="color: var(--mc-text-muted); font-size: 12px; margin: 0 0 10px;">Convide seus amigos para fazer parte da comunidade:</p>
                    <button type="button" onclick="openInviteModal()" style="background: #28a745; color: #fff; border: none; padding: 10px 20px; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 600;">
                        📨 Convidar Amigos
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Coluna lateral: Perfil, pontuacao, atalhos e stories -->
    <div class="dashboard-sidebar">
        <!-- Card do avatar do usuario -->
        <div class="card" style="text-align: center; padding: 25px; background: #f0f4ff; border: 1px solid #c5d5f5; border-radius: 16px;">
            <?php if (!empty($profile['avatar'])): ?>
                <img src="<?= htmlspecialchars($profile['avatar']) ?>" alt="Avatar" style="width: 120px; height: 120px; border-radius: 50%; object-fit: cover; border: 3px solid var(--mc-primary); margin: 0 auto 15px;">
            <?php else: ?>
                <div style="width: 120px; height: 120px; border-radius: 50%; background: var(--mc-bg-hover); border: 3px solid var(--mc-primary); margin: 0 auto 15px; display: flex; align-items: center; justify-content: center; font-size: 45px; color: var(--mc-text-light);">
                    <?= strtoupper(substr($profile['name'] ?? 'U', 0, 1)) ?>
                </div>
            <?php endif; ?>
            <h2 style="color: var(--mc-text); border: none; padding: 0; font-size: 20px;"><?= htmlspecialchars($profile['name']) ?></h2>
            <p style="color: var(--mc-text-muted); font-size: 12px; margin-top: 3px;"><?= ucfirst($profile['role']) ?></p>
            <a href="/profile" style="display: inline-block; margin-top: 15px; color: var(--mc-text-muted); font-size: 12px; text-decoration: none;">Editar perfil</a>
        </div>

        <!-- Card de gamificacao -->
        <div class="card" style="padding: 15px; background: #fff5f0; border: 1px solid #f5d5c5; border-radius: 16px;">
            <h3 style="color: var(--mc-text); border: none; padding: 0; margin: 0 0 15px 0; font-size: 15px;">&#127942; Minha pontuacao</h3>
            <div style="display: flex; flex-direction: column; gap: 6px;">
                <div title="Seu nivel atual no sistema. Sobe a cada 1000 XP acumulado." style="display: flex; justify-content: space-between; padding: 8px 12px; background: rgba(255,255,255,0.7); border-radius: 6px; cursor: help;">
                    <span style="color: var(--mc-text-muted); font-size: 13px;">Nivel atual</span>
                    <span style="color: var(--mc-primary); font-size: 13px; font-weight: bold;"><?= (int)($gamification['level'] ?? 1) ?></span>
                </div>
                <div title="Pontos de experiencia (XP) ganhos em todas as atividades: viagens, eventos, fotos, medalhas e desafios." style="display: flex; justify-content: space-between; padding: 8px 12px; background: rgba(255,255,255,0.7); border-radius: 6px; cursor: help;">
                    <span style="color: var(--mc-text-muted); font-size: 13px;">XP Geral</span>
                    <span style="color: var(--mc-text); font-size: 13px; font-weight: bold;"><?= number_format((int)($gamification['xp'] ?? 0), 0, ',', '.') ?></span>
                </div>
                <div title="Ride Score: pontua sua experiencia como motociclista. Sobe com viagens, rotas percorridas e participacao em eventos." style="display: flex; justify-content: space-between; padding: 8px 12px; background: rgba(255,255,255,0.7); border-radius: 6px; cursor: help;">
                    <span style="color: var(--mc-text-muted); font-size: 13px;">Ride Score</span>
                    <span style="color: var(--mc-text); font-size: 13px; font-weight: bold;"><?= number_format((int)($gamification['ride_score'] ?? 0), 0, ',', '.') ?></span>
                </div>
                <div title="Trust Score: medida de confianca da comunidade em voce. Sobe com verificacoes, recomendacoes e bom comportamento." style="display: flex; justify-content: space-between; padding: 8px 12px; background: rgba(255,255,255,0.7); border-radius: 6px; cursor: help;">
                    <span style="color: var(--mc-text-muted); font-size: 13px;">Trust Score</span>
                    <span style="color: var(--mc-text); font-size: 13px; font-weight: bold;"><?= number_format((int)($gamification['trust_score'] ?? 0), 0, ',', '.') ?></span>
                </div>
                <div title="Medalhas conquistadas por atingir objetivos especificos: distancia percorrida, eventos, exploracao de rotas e mais." style="display: flex; justify-content: space-between; padding: 8px 12px; background: rgba(255,255,255,0.7); border-radius: 6px; cursor: help;">
                    <span style="color: var(--mc-text-muted); font-size: 13px;">Medalhas</span>
                    <span style="color: var(--mc-text); font-size: 13px; font-weight: bold;"><?= count($gamification['medals'] ?? []) ?></span>
                </div>
                <?php if (!empty($gamification['medals'])): ?>
                <div style="display: flex; flex-wrap: wrap; gap: 6px; margin-top: 8px; padding: 8px 12px; background: rgba(255,255,255,0.7); border-radius: 6px;">
                    <?php foreach (array_slice($gamification['medals'], 0, 8) as $medal): ?>
                    <span title="<?= htmlspecialchars($medal['name'] ?? '') ?>: <?= htmlspecialchars($medal['description'] ?? '') ?>" style="font-size: 20px; cursor: help;"><?= htmlspecialchars($medal['icon'] ?? '&#127942;') ?></span>
                    <?php endforeach; ?>
                </div>
                <?php endif; ?>
            </div>
            <a href="/gamification" style="display: block; text-align: center; margin-top: 12px; padding: 8px; color: var(--mc-primary); font-size: 13px; text-decoration: none; border-top: 1px solid rgba(245,213,197,0.5);">Ver gamificacao completa &raquo;</a>
        </div>

        <!-- Card de atalhos -->
        <div class="card" style="padding: 15px; background: #f0fff5; border: 1px solid #c5f5d5; border-radius: 16px;">
            <h3 style="color: var(--mc-text); border: none; padding: 0; margin: 0 0 15px 0; font-size: 15px;">Atalhos</h3>
            <div style="display: flex; flex-direction: column; gap: 8px;">
                <a href="/clubs" style="display: flex; align-items: center; gap: 10px; padding: 10px 12px; background: rgba(255,255,255,0.7); border-radius: 8px; text-decoration: none; color: var(--mc-text); font-size: 14px; transition: all 0.2s;" onmouseover="this.style.background='rgba(255,255,255,1)'" onmouseout="this.style.background='rgba(255,255,255,0.7)'">
                    <span style="font-size: 18px;">&#127968;</span> Meus Clubes
                </a>
                <a href="/motorcycles" style="display: flex; align-items: center; gap: 10px; padding: 10px 12px; background: rgba(255,255,255,0.7); border-radius: 8px; text-decoration: none; color: var(--mc-text); font-size: 14px; transition: all 0.2s;" onmouseover="this.style.background='rgba(255,255,255,1)'" onmouseout="this.style.background='rgba(255,255,255,0.7)'">
                    <span style="font-size: 18px;">&#127949;</span> Minhas Motos
                </a>
                <a href="/routes" style="display: flex; align-items: center; gap: 10px; padding: 10px 12px; background: rgba(255,255,255,0.7); border-radius: 8px; text-decoration: none; color: var(--mc-text); font-size: 14px; transition: all 0.2s;" onmouseover="this.style.background='rgba(255,255,255,1)'" onmouseout="this.style.background='rgba(255,255,255,0.7)'">
                    <span style="font-size: 18px;">&#128506;</span> Rotas
                </a>
                <a href="/social-groups" style="display: flex; align-items: center; gap: 10px; padding: 10px 12px; background: rgba(255,255,255,0.7); border-radius: 8px; text-decoration: none; color: var(--mc-text); font-size: 14px; transition: all 0.2s;" onmouseover="this.style.background='rgba(255,255,255,1)'" onmouseout="this.style.background='rgba(255,255,255,0.7)'">
                    <span style="font-size: 18px;">&#128101;</span> Grupos
                </a>
            </div>
        </div>

        <div class="card" style="padding: 15px; background: #fff5f5; border: 1px solid #f5d5d5; border-radius: 16px;">
            <h3 style="color: var(--mc-text); border: none; padding: 0; margin: 0 0 15px 0; font-size: 15px;">&#128247; Novidades na Rede</h3>

            <?php if (!empty($photoFeed)): ?>
            <div id="stories-container" style="position: relative; overflow: hidden; border: 1px solid var(--mc-border); border-radius: 8px;">
                <div id="stories-track" style="display: flex; transition: transform 0.4s ease;">
                    <?php foreach ($photoFeed as $photo): ?>
                    <div class="story-item" style="min-width: 100%; position: relative;">
                        <div style="width: 100%; aspect-ratio: 4/3; overflow: hidden; cursor: pointer;" onclick="openStoryModal(<?= $photo['photo_id'] ?>)">
                            <img src="<?= htmlspecialchars($photo['filename']) ?>" alt="Foto" style="width: 100%; height: 100%; object-fit: cover;">
                        </div>
                        <div style="padding: 10px; position: absolute; bottom: 0; left: 0; right: 0; background: linear-gradient(transparent, rgba(0,0,0,0.85));">
                            <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 4px;">
                                <?php if (!empty($photo['user_avatar'])): ?>
                                    <img src="<?= htmlspecialchars($photo['user_avatar']) ?>" alt="" style="width: 22px; height: 22px; border-radius: 50%; object-fit: cover; border: 1px solid var(--mc-primary);">
                                <?php else: ?>
                                    <div style="width: 22px; height: 22px; border-radius: 50%; background: var(--mc-bg-hover); display: flex; align-items: center; justify-content: center; color: var(--mc-text-light); font-size: 10px; border: 1px solid var(--mc-primary);"><?= strtoupper(substr($photo['user_name'], 0, 1)) ?></div>
                                <?php endif; ?>
                                <span style="color: #ccc; font-size: 11px;"><?= htmlspecialchars($photo['user_name']) ?></span>
                            </div>
                            <?php if (!empty($photo['album_title'])): ?>
                                <p style="color: var(--mc-primary); font-size: 10px; margin-bottom: 3px;"><?= htmlspecialchars($photo['album_title']) ?></p>
                            <?php endif; ?>
                            <?php if (!empty($photo['caption'])): ?>
                                <p style="color: #aaa; font-size: 11px; line-height: 1.3;"><?= htmlspecialchars($photo['caption']) ?></p>
                            <?php endif; ?>
                            <p style="color: #666; font-size: 9px; margin-top: 4px;"><?= date('d/m/Y H:i', strtotime($photo['created_at'])) ?></p>
                        </div>
                    </div>
                    <?php endforeach; ?>
                </div>

                <!-- Barra de progresso -->
                <div id="stories-progress" style="display: flex; gap: 4px; padding: 8px 10px; position: absolute; top: 0; left: 0; right: 0; z-index: 10;">
                    <?php for ($i = 0; $i < count($photoFeed); $i++): ?>
                    <div class="progress-bar" style="flex: 1; height: 2px; background: rgba(255,255,255,0.3); transition: background 0.3s;"></div>
                    <?php endfor; ?>
                </div>

                <!-- Botao anterior -->
                <button id="story-prev" style="position: absolute; top: 50%; left: 5px; transform: translateY(-50%); background: rgba(0,0,0,0.5); color: #fff; border: none; border-radius: 50%; width: 30px; height: 30px; cursor: pointer; font-size: 16px; z-index: 10; display: flex; align-items: center; justify-content: center;">&#8249;</button>

                <!-- Botao proximo -->
                <button id="story-next" style="position: absolute; top: 50%; right: 5px; transform: translateY(-50%); background: rgba(0,0,0,0.5); color: #fff; border: none; border-radius: 50%; width: 30px; height: 30px; cursor: pointer; font-size: 16px; z-index: 10; display: flex; align-items: center; justify-content: center;">&#8250;</button>
            </div>

            <p style="color: var(--mc-text-light); font-size: 10px; text-align: center; margin-top: 8px;">Arraste ou use as setas para navegar &middot; <?= count($photoFeed) ?> fotos</p>

            <script>
            (function() {
                var track = document.getElementById('stories-track');
                var container = document.getElementById('stories-container');
                var bars = document.querySelectorAll('.progress-bar');
                var current = 0;
                var total = <?= count($photoFeed) ?>;

                function updateSlide() {
                    track.style.transform = 'translateX(-' + (current * 100) + '%)';
                    bars.forEach(function(bar, i) {
                        bar.style.background = i <= current ? 'var(--mc-primary)' : 'rgba(255,255,255,0.3)';
                    });
                }

                function next() {
                    if (current < total - 1) {
                        current++;
                        updateSlide();
                    } else {
                        current = 0;
                        updateSlide();
                    }
                }

                function prev() {
                    if (current > 0) {
                        current--;
                        updateSlide();
                    } else {
                        current = total - 1;
                        updateSlide();
                    }
                }

                document.getElementById('story-next').addEventListener('click', next);
                document.getElementById('story-prev').addEventListener('click', prev);

                // Auto-play a cada 5 segundos
                var autoPlay = setInterval(next, 5000);

                // Pausa auto-play ao interagir
                container.addEventListener('mouseenter', function() { clearInterval(autoPlay); });
                container.addEventListener('mouseleave', function() { autoPlay = setInterval(next, 5000); });

                // Touch/swipe
                var startX = 0;
                var startY = 0;
                var isDragging = false;

                container.addEventListener('touchstart', function(e) {
                    startX = e.touches[0].clientX;
                    startY = e.touches[0].clientY;
                    isDragging = true;
                    clearInterval(autoPlay);
                });

                container.addEventListener('touchend', function(e) {
                    if (!isDragging) return;
                    isDragging = false;
                    var endX = e.changedTouches[0].clientX;
                    var endY = e.changedTouches[0].clientY;
                    var diffX = startX - endX;
                    var diffY = startY - endY;
                    if (Math.abs(diffX) > Math.abs(diffY) && Math.abs(diffX) > 30) {
                        if (diffX > 0) { next(); } else { prev(); }
                    }
                    autoPlay = setInterval(next, 5000);
                });

                // Mouse drag
                var mouseStartX = 0;
                var mouseIsDown = false;

                container.addEventListener('mousedown', function(e) {
                    mouseStartX = e.clientX;
                    mouseIsDown = true;
                });

                container.addEventListener('mouseup', function(e) {
                    if (!mouseIsDown) return;
                    mouseIsDown = false;
                    var diff = mouseStartX - e.clientX;
                    if (Math.abs(diff) > 50) {
                        if (diff > 0) { next(); } else { prev(); }
                    }
                });

                container.addEventListener('mouseleave', function() {
                    mouseIsDown = false;
                });

                updateSlide();
            })();
            </script>
            <?php else: ?>
            <div style="text-align: center; padding: 30px;">
                <span style="font-size: 40px; color: var(--mc-text-light);">&#128247;</span>
                <p style="color: var(--mc-text-muted); font-size: 13px; margin-top: 10px;">Nenhuma foto publica ainda.</p>
                <a href="/album" style="font-size: 12px; color: var(--mc-primary);">Criar album publico &raquo;</a>
            </div>
            <?php endif; ?>
        </div>

        <!-- Card de estatísticas da comunidade -->
        <div class="card" style="padding: 15px; background: #f0f4ff; border: 1px solid #c5d5f5; border-radius: 16px;">
            <h3 style="color: var(--mc-text); border: none; padding: 0; margin: 0 0 15px 0; font-size: 15px;">&#128202; Comunidade</h3>
            <div style="display: flex; flex-direction: column; gap: 6px;">
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 10px 12px; background: rgba(255,255,255,0.7); border-radius: 8px;">
                    <div style="display: flex; align-items: center; gap: 8px;">
                        <span style="font-size: 18px;">&#127757;</span>
                        <span style="color: var(--mc-text-muted); font-size: 13px;">Novos usuários</span>
                    </div>
                    <span style="color: var(--mc-primary); font-size: 16px; font-weight: bold;"><?= number_format((int)($communityStats['new_users'] ?? 0), 0, ',', '.') ?></span>
                </div>
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 10px 12px; background: rgba(255,255,255,0.7); border-radius: 8px;">
                    <div style="display: flex; align-items: center; gap: 8px;">
                        <span style="font-size: 18px;">&#128101;</span>
                        <span style="color: var(--mc-text-muted); font-size: 13px;">Grupos ativos</span>
                    </div>
                    <span style="color: var(--mc-text); font-size: 16px; font-weight: bold;"><?= number_format((int)($communityStats['total_groups'] ?? 0), 0, ',', '.') ?></span>
                </div>
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 10px 12px; background: rgba(255,255,255,0.7); border-radius: 8px;">
                    <div style="display: flex; align-items: center; gap: 8px;">
                        <span style="font-size: 18px;">&#127949;</span>
                        <span style="color: var(--mc-text-muted); font-size: 13px;">Motos cadastradas</span>
                    </div>
                    <span style="color: var(--mc-text); font-size: 16px; font-weight: bold;"><?= number_format((int)($communityStats['total_motos'] ?? 0), 0, ',', '.') ?></span>
                </div>
            </div>
            <div style="margin-top: 10px; padding-top: 10px; border-top: 1px solid rgba(197,213,245,0.5); text-align: center;">
                <p style="color: var(--mc-text-muted); font-size: 11px; margin: 0;">
                    &#127757; <?= number_format((int)($communityStats['total_users'] ?? 0), 0, ',', '.') ?> membros na rede
                </p>
            </div>
        </div>
    </div>
</div>

<!-- Modal de Convite -->
<div id="inviteModal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.85); z-index:9999; align-items:center; justify-content:center;">
    <div class="dashboard-invite-modal" style="background:#111; border:1px solid #333; border-radius:16px; padding:35px; max-width:500px; width:90%; position:relative;">
        <button type="button" onclick="closeInviteModal()" style="position:absolute; top:15px; right:15px; background:none; border:none; color:#888; font-size:24px; cursor:pointer;">&times;</button>
        <h2 style="color:#fff; font-size:22px; text-align:center; margin-bottom:10px;">🎉 Convidar Amigos</h2>
        <p style="color:#888; font-size:14px; text-align:center; margin-bottom:25px;">Ganhe <strong style="color:#e30613;">100 pontos</strong> por cada amigo que se cadastrar pelo seu link!</p>

        <!-- Escolher plataforma -->
        <div id="invitePlatforms" class="dashboard-invite-grid">
            <button type="button" onclick="generateInvite('email')" style="padding:18px; background:#1a1a1a; border:1px solid #333; border-radius:10px; color:#ccc; font-size:15px; cursor:pointer; transition:all 0.2s;">
                📧 Email
            </button>
            <button type="button" onclick="generateInvite('whatsapp')" style="padding:18px; background:#1a1a1a; border:1px solid #333; border-radius:10px; color:#ccc; font-size:15px; cursor:pointer; transition:all 0.2s;">
                💬 WhatsApp
            </button>
            <button type="button" onclick="generateInvite('facebook')" style="padding:18px; background:#1a1a1a; border:1px solid #333; border-radius:10px; color:#ccc; font-size:15px; cursor:pointer; transition:all 0.2s;">
                📘 Facebook
            </button>
            <button type="button" onclick="generateInvite('instagram')" style="padding:18px; background:#1a1a1a; border:1px solid #333; border-radius:10px; color:#ccc; font-size:15px; cursor:pointer; transition:all 0.2s;">
                📸 Instagram
            </button>
        </div>

        <!-- Área do link gerado -->
        <div id="inviteResult" style="display:none;">
            <div style="background:#0a0a0a; border:1px solid #333; border-radius:8px; padding:15px; margin-bottom:15px;">
                <label style="color:#888; font-size:12px; display:block; margin-bottom:8px;">Seu link de convite:</label>
                <div style="display:flex; gap:8px;">
                    <input type="text" id="inviteLinkInput" readonly style="flex:1; padding:10px; background:#111; border:1px solid #333; color:#ccc; border-radius:6px; font-size:13px;">
                    <button type="button" onclick="copyInviteLink()" style="padding:10px 16px; background:#e30613; color:#fff; border:none; border-radius:6px; cursor:pointer; font-size:13px; white-space:nowrap;">Copiar</button>
                </div>
            </div>

            <!-- Botões de compartilhamento -->
            <div id="shareButtons" style="display:flex; gap:10px; flex-wrap:wrap; justify-content:center;">
                <a id="shareEmail" href="#" target="_blank" style="padding:10px 20px; background:#555; color:#fff; border-radius:8px; text-decoration:none; font-size:13px;">📧 Enviar por Email</a>
                <a id="shareWhatsapp" href="#" target="_blank" style="padding:10px 20px; background:#25D366; color:#fff; border-radius:8px; text-decoration:none; font-size:13px;">💬 WhatsApp</a>
                <a id="shareFacebook" href="#" target="_blank" style="padding:10px 20px; background:#1877F2; color:#fff; border-radius:8px; text-decoration:none; font-size:13px;">📘 Facebook</a>
                <a id="shareInstagram" href="#" target="_blank" style="padding:10px 20px; background:#E1306C; color:#fff; border-radius:8px; text-decoration:none; font-size:13px;">📸 Instagram</a>
            </div>

            <div style="margin-top:15px; text-align:center;">
                <button type="button" onclick="closeInviteModal()" style="padding:8px 24px; background:transparent; border:1px solid #444; color:#888; border-radius:6px; cursor:pointer; font-size:13px;">Fechar</button>
            </div>
        </div>

        <!-- Estatísticas -->
        <div id="inviteStats" style="margin-top:20px; padding:15px; background:#0a0a0a; border-radius:8px; display:none;">
            <h4 style="color:#ccc; font-size:13px; margin-bottom:10px;">📊 Suas Indicações</h4>
            <div style="display:flex; justify-content:space-around; text-align:center;">
                <div><div id="statClicks" style="color:#ffcc00; font-size:20px; font-weight:bold;">0</div><div style="color:#555; font-size:11px;">Cliques</div></div>
                <div><div id="statRegs" style="color:#28a745; font-size:20px; font-weight:bold;">0</div><div style="color:#555; font-size:11px;">Cadastros</div></div>
                <div><div id="statPoints" style="color:#e30613; font-size:20px; font-weight:bold;">0</div><div style="color:#555; font-size:11px;">Pontos</div></div>
            </div>
        </div>
    </div>
</div>

<script>
function openInviteModal() {
    var modal = document.getElementById('inviteModal');
    modal.style.display = 'flex';
    document.getElementById('invitePlatforms').style.display = 'grid';
    document.getElementById('inviteResult').style.display = 'none';
    loadInviteStats();
}

function closeInviteModal() {
    document.getElementById('inviteModal').style.display = 'none';
}

function generateInvite(platform) {
    var btns = document.querySelectorAll('#invitePlatforms button');
    btns.forEach(function(b) { b.disabled = true; b.style.opacity = '0.5'; });

    fetch('/referral/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'platform=' + platform
    })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (data.success) {
            var url = data.url;
            var msg = 'Olá! Entre na maior comunidade de motociclistas do Brasil! Cadastre-se no MotoHead: ' + url;

            document.getElementById('inviteLinkInput').value = url;
            document.getElementById('invitePlatforms').style.display = 'none';
            document.getElementById('inviteResult').style.display = 'block';

            // Configura botões de compartilhamento
            document.getElementById('shareEmail').href = 'mailto:?subject=Convite%20MotoHead&body=' + encodeURIComponent(msg);
            document.getElementById('shareWhatsapp').href = 'https://wa.me/?text=' + encodeURIComponent(msg);

            if (platform === 'facebook') {
                document.getElementById('shareFacebook').href = 'https://www.facebook.com/sharer/sharer.php?u=' + encodeURIComponent(url);
                document.getElementById('shareInstagram').style.display = 'none';
            } else if (platform === 'instagram') {
                document.getElementById('shareInstagram').href = url;
                document.getElementById('shareInstagram').target = '_self';
                document.getElementById('shareInstagram').textContent = '📸 Copiar e colar no Instagram';
                document.getElementById('shareFacebook').style.display = 'inline-block';
                document.getElementById('shareFacebook').href = 'https://www.facebook.com/sharer/sharer.php?u=' + encodeURIComponent(url);
            } else {
                document.getElementById('shareFacebook').href = 'https://www.facebook.com/sharer/sharer.php?u=' + encodeURIComponent(url);
                document.getElementById('shareInstagram').href = url;
                document.getElementById('shareInstagram').target = '_self';
                document.getElementById('shareInstagram').textContent = '📸 Copiar e colar no Instagram';
            }

            // Mostra/oculta botões conforme plataforma
            var shareBtns = document.getElementById('shareButtons').children;
            for (var i = 0; i < shareBtns.length; i++) {
                shareBtns[i].style.display = 'inline-block';
            }
            if (platform === 'email') {
                document.getElementById('shareWhatsapp').style.display = 'none';
                document.getElementById('shareFacebook').style.display = 'none';
                document.getElementById('shareInstagram').style.display = 'none';
            } else if (platform === 'whatsapp') {
                document.getElementById('shareEmail').style.display = 'none';
                document.getElementById('shareFacebook').style.display = 'none';
                document.getElementById('shareInstagram').style.display = 'none';
            } else if (platform === 'facebook') {
                document.getElementById('shareEmail').style.display = 'none';
                document.getElementById('shareWhatsapp').style.display = 'none';
                document.getElementById('shareInstagram').style.display = 'none';
            } else if (platform === 'instagram') {
                document.getElementById('shareEmail').style.display = 'none';
                document.getElementById('shareWhatsapp').style.display = 'none';
                document.getElementById('shareFacebook').style.display = 'none';
            }
        } else {
            alert('Erro ao gerar link. Tente novamente.');
        }
    })
    .catch(function(err) {
        alert('Erro: ' + err.message);
    })
    .finally(function() {
        btns.forEach(function(b) { b.disabled = false; b.style.opacity = '1'; });
    });
}

function copyInviteLink() {
    var input = document.getElementById('inviteLinkInput');
    input.select();
    input.setSelectionRange(0, 99999);
    try {
        document.execCommand('copy');
        var btn = event.target;
        var original = btn.textContent;
        btn.textContent = '✅ Copiado!';
        setTimeout(function() { btn.textContent = original; }, 2000);
    } catch (e) {
        alert('Não foi possível copiar. Selecione e copie manualmente.');
    }
}

function loadInviteStats() {
    fetch('/referral/stats')
        .then(function(r) { return r.json(); })
        .then(function(data) {
            if (data.success && data.stats) {
                document.getElementById('statClicks').textContent = data.stats.total_clicks || 0;
                document.getElementById('statRegs').textContent = data.stats.total_registrations || 0;
                document.getElementById('statPoints').textContent = data.stats.total_points || 0;
                if (data.stats.total_links > 0 || data.stats.total_clicks > 0) {
                    document.getElementById('inviteStats').style.display = 'block';
                }
            }
        })
        .catch(function() {});
}

// Fecha modal ao clicar no overlay
document.getElementById('inviteModal').addEventListener('click', function(e) {
    if (e.target === this) closeInviteModal();
});
</script>

<?php
$infoTitle = 'Como funciona o Dashboard';
$infoItems = [
    ['icon' => '📅', 'title' => 'Próximos Eventos', 'desc' => 'Mostra os 4 próximos eventos da comunidade. Clique para ver detalhes ou confirmar presença.'],
    ['icon' => '👤', 'title' => 'Card do Perfil', 'desc' => 'Exibe seu avatar, nome e função. Use o botão "Convidar Amigos" para gerar links de convite e ganhar pontos.'],
    ['icon' => '🔗', 'title' => 'Link de Convite', 'desc' => 'Gere links personalizados para compartilhar com amigos. Cada cadastro via link rende pontos para você.'],
    ['icon' => '📊', 'title' => 'Estatísticas', 'desc' => 'Acompanhe cliques, registros e pontos ganhos através dos seus links de convite.'],
];
$infoTip = 'Mantenha seu perfil atualizado e compartilhe seus links de convite para acumular pontos mais rápido!';
require __DIR__ . '/../partials/info_box.php';
?>

<?php if (!empty($photoFeed)): ?>
<!-- Modal de visualização de foto das histórias -->
<div id="story-modal" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.92); z-index: 99999; align-items: center; justify-content: center;" onclick="closeStoryModal(event)">
    <div style="max-width: 700px; width: 90%; max-height: 90%; display: flex; flex-direction: column;" onclick="event.stopPropagation()">
        <!-- Imagem ampliada -->
        <div style="width: 100%; aspect-ratio: 4/3; overflow: hidden; border-radius: 8px 8px 0 0; background: #000;">
            <img id="story-modal-img" src="" alt="" style="width: 100%; height: 100%; object-fit: contain;">
        </div>

        <!-- Info e interações -->
        <div id="story-modal-content" style="background: var(--mc-bg-card); border: 1px solid var(--mc-border); border-top: none; border-radius: 0 0 8px 8px; padding: 15px; max-height: 300px; overflow-y: auto;">
            <!-- Preenchido via JS -->
        </div>

        <div style="text-align: center; margin-top: 10px;">
            <button type="button" onclick="closeStoryModal()" style="background: #2a2a2a; color: #fff; border: 1px solid #555; border-radius: 4px; padding: 8px 20px; cursor: pointer; font-size: 13px;">Fechar</button>
        </div>
    </div>
</div>

<script>
var storyPhotos = <?= json_encode($photoFeed) ?>;
var csrfField = '<?= CsrfMiddleware::field() ?>';

function openStoryModal(photoId) {
    var photo = storyPhotos.find(function(p) { return parseInt(p.photo_id) === parseInt(photoId); });
    if (!photo) return;

    document.getElementById('story-modal-img').src = photo.filename;

    var commentsHtml = '';
    if (photo.comments && photo.comments.length > 0) {
        photo.comments.forEach(function(c) {
            var avatar = c.user_avatar
                ? '<img src="' + c.user_avatar + '" style="width:24px;height:24px;border-radius:50%;object-fit:cover;">'
                : '<div style="width:24px;height:24px;border-radius:50%;background:#333;display:flex;align-items:center;justify-content:center;color:#999;font-size:10px;">' + (c.user_name || 'U').charAt(0).toUpperCase() + '</div>';
            commentsHtml += '<div style="display:flex;gap:8px;margin-bottom:10px;">' +
                '<div style="flex-shrink:0;">' + avatar + '</div>' +
                '<div><strong style="color:var(--mc-text);font-size:12px;">' + (c.user_name || '') + '</strong>' +
                '<p style="color:var(--mc-text);font-size:12px;margin:2px 0 0 0;">' + (c.content || '') + '</p>' +
                '<span style="color:var(--mc-text-muted);font-size:10px;">' + new Date((c.created_at || '').replace(' ', 'T')).toLocaleString('pt-BR') + '</span></div></div>';
        });
    } else {
        commentsHtml = '<p style="color:var(--mc-text-muted);font-size:12px;text-align:center;">Nenhum comentário ainda.</p>';
    }

    var likeBtn = photo.user_liked ? '❤️' : '🤍';
    var likeColor = photo.user_liked ? 'var(--mc-primary)' : 'var(--mc-text-muted)';

    document.getElementById('story-modal-content').innerHTML =
        '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;padding-bottom:8px;border-bottom:1px solid var(--mc-border);">' +
            '<div><strong style="color:var(--mc-text);font-size:13px;">' + (photo.caption || 'Foto') + '</strong>' +
            '<p style="color:var(--mc-text-muted);font-size:11px;margin:2px 0 0 0;">por ' + (photo.user_name || '') + (photo.album_title ? ' · ' + photo.album_title : '') + '</p></div>' +
            '<form method="POST" action="/album/like/' + photo.album_id + '" style="display:inline;">' +
                csrfField +
                '<input type="hidden" name="photo_id" value="' + photo.photo_id + '">' +
                '<button type="submit" style="background:none;border:none;cursor:pointer;color:' + likeColor + ';font-size:14px;padding:0;">' + likeBtn + ' ' + (photo.like_count || 0) + '</button>' +
            '</form>' +
        '</div>' +
        '<div style="margin-bottom:10px;max-height:150px;overflow-y:auto;">' + commentsHtml + '</div>' +
        '<form method="POST" action="/album/comment/' + photo.album_id + '" style="display:flex;gap:8px;">' +
            csrfField +
            '<input type="hidden" name="photo_id" value="' + photo.photo_id + '">' +
            '<input type="text" name="content" placeholder="Escreva um comentário..." required style="flex:1;font-size:12px;padding:6px 10px;">' +
            '<button type="submit" class="btn" style="padding:6px 12px;font-size:12px;">Comentar</button>' +
        '</form>';

    document.getElementById('story-modal').style.display = 'flex';
}

function closeStoryModal(e) {
    if (e && e.target.closest('#story-modal > div')) return;
    document.getElementById('story-modal').style.display = 'none';
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closeStoryModal();
});
</script>
<?php endif; ?>

<script>
(function() {
    var feedContainer = document.getElementById('infinite-feed');
    var loader = document.getElementById('feed-loader');
    var endMsg = document.getElementById('feed-end');
    if (!feedContainer) return;

    var currentPage = 1;
    var loading = false;
    var hasMore = true;

    function escapeHtml(str) {
        if (!str) return '';
        var div = document.createElement('div');
        div.textContent = str;
        return div.innerHTML;
    }

    function renderPost(post) {
        var avatar = post.author_avatar
            ? '<img src="' + escapeHtml(post.author_avatar) + '" alt="Avatar" style="width:40px;height:40px;border-radius:50%;object-fit:cover;border:2px solid var(--mc-primary);">'
            : '<div style="width:40px;height:40px;border-radius:50%;background:var(--mc-bg-hover);border:2px solid var(--mc-primary);display:flex;align-items:center;justify-content:center;color:var(--mc-text-light);font-size:16px;">' + escapeHtml((post.author_name || '?').charAt(0).toUpperCase()) + '</div>';

        var sourceType = post.source_type || 'post';
        var typeLabels = {
            'post': '📝 Publicação',
            'photo': '📷 Foto',
            'story': '📖 História',
            'travel': '🗺️ Viagem'
        };
        var typeLabel = typeLabels[sourceType] || '📝 Publicação';
        var linkUrl = '#';
        if (sourceType === 'post') linkUrl = '/feed/show/' + post.entity_id;
        else if (sourceType === 'photo') linkUrl = '/album/show/' + post.entity_id;
        else if (sourceType === 'story') linkUrl = '/stories/show/' + post.entity_id;
        else if (sourceType === 'travel') linkUrl = '/travels/show/' + post.entity_id;

        var body = '';
        if (post.title && sourceType !== 'post') {
            body += '<div style="padding:0 15px 8px 15px;color:var(--mc-text);font-size:15px;font-weight:bold;">' + escapeHtml(post.title) + '</div>';
        }
        if (post.description) {
            var descText = sourceType === 'post' ? post.description : post.description;
            if (descText && descText.length > 200) descText = descText.substring(0, 200) + '...';
            body += '<div style="padding:0 15px 12px 15px;color:var(--mc-text);font-size:14px;line-height:1.6;white-space:pre-wrap;">' + escapeHtml(descText).replace(/\n/g, '<br>') + '</div>';
        }

        var media = '';
        if (post.image) {
            media = '<a href="' + linkUrl + '"><img src="' + escapeHtml(post.image) + '" alt="Imagem" style="width:100%;max-height:500px;object-fit:cover;display:block;background:#000;"></a>';
        }

        var bgColors = ['#f0f4ff', '#f0fff5', '#fff5f0', '#fff5f5', '#f5f0ff', '#fffff0', '#f0ffff', '#fff0f5'];
        var bgColor = bgColors[(post.entity_id % bgColors.length)];

        return '<div class="card" style="padding:0;overflow:hidden;margin-bottom:12px;border-radius:12px;background:' + bgColor + ';border:1px solid rgba(0,0,0,0.05);">' +
            '<div style="display:flex;align-items:center;gap:10px;padding:12px 15px;">' +
                '<a href="/feed/user/' + post.user_id + '" style="text-decoration:none;">' + avatar + '</a>' +
                '<div style="flex:1;">' +
                    '<a href="/feed/user/' + post.user_id + '" style="color:var(--mc-text);font-weight:bold;font-size:13px;text-decoration:none;">' + escapeHtml(post.author_name) + '</a>' +
                    '<div style="color:var(--mc-text-muted);font-size:11px;display:flex;align-items:center;gap:5px;">' +
                        '<span style="background:rgba(0,0,0,0.05);padding:1px 6px;border-radius:4px;font-size:10px;">' + typeLabel + '</span>' +
                        '<span>' + escapeHtml(post.time_ago) + '</span>' +
                    '</div>' +
                '</div>' +
            '</div>' +
            body + media +
            '<div style="display:flex;border-top:1px solid var(--mc-border);">' +
                '<a href="' + linkUrl + '" style="flex:1;color:var(--mc-text-muted);padding:10px;text-align:center;font-size:12px;text-decoration:none;display:flex;align-items:center;justify-content:center;gap:5px;">❤️ ' + (post.likes_count || 0) + '</a>' +
                '<a href="' + linkUrl + '" style="flex:1;color:var(--mc-text-muted);padding:10px;text-align:center;font-size:12px;text-decoration:none;display:flex;align-items:center;justify-content:center;gap:5px;border-left:1px solid var(--mc-border);border-right:1px solid var(--mc-border);">💬 ' + (post.comments_count || 0) + '</a>' +
                '<a href="' + linkUrl + '" style="flex:1;color:var(--mc-text-muted);padding:10px;text-align:center;font-size:12px;text-decoration:none;display:flex;align-items:center;justify-content:center;gap:5px;">🔁 ' + (post.shares_count || 0) + '</a>' +
            '</div>' +
        '</div>';
    }

    function loadMore() {
        if (loading || !hasMore) return;
        loading = true;
        loader.style.display = 'block';

        fetch('/api/feed?page=' + currentPage)
            .then(function(r) { return r.json(); })
            .then(function(data) {
                loading = false;
                loader.style.display = 'none';

                if (!data.success || !data.posts || data.posts.length === 0) {
                    hasMore = false;
                    endMsg.style.display = 'block';
                    if (currentPage === 1) {
                        feedContainer.innerHTML = '<div style="text-align:center;padding:40px;"><span style="font-size:40px;">📰</span><p style="color:var(--mc-text-muted);font-size:13px;margin-top:10px;">Nenhuma publicação ainda.</p><a href="/feed/create" style="font-size:12px;color:var(--mc-primary);">Criar post &raquo;</a></div>';
                    }
                    return;
                }

                data.posts.forEach(function(post) {
                    feedContainer.insertAdjacentHTML('beforeend', renderPost(post));
                });

                hasMore = data.hasMore;
                currentPage++;

                if (!hasMore) {
                    endMsg.style.display = 'block';
                }
            })
            .catch(function() {
                loading = false;
                loader.style.display = 'none';
            });
    }

    var observer = new IntersectionObserver(function(entries) {
        if (entries[0].isIntersecting) {
            loadMore();
        }
    }, { rootMargin: '200px' });

    observer.observe(loader);

    loadMore();
})();
</script>

<?php
$content = ob_get_clean();
require_once __DIR__ . '/../layouts/main.php';
