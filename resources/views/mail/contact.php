<?php ob_start(); ?>
<div class="container mt-5 mb-5">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card bg-dark text-light border-secondary">
                <div class="card-header text-center">
                    <h3 class="mb-0">✉️ Fale Conosco</h3>
                </div>
                <div class="card-body">
                    <?php if (isset($_SESSION['success'])): ?>
                        <div class="alert alert-success">
                            <?= $_SESSION['success']; unset($_SESSION['success']); ?>
                        </div>
                    <?php endif; ?>
                    <?php if (isset($_SESSION['error'])): ?>
                        <div class="alert alert-danger">
                            <?= $_SESSION['error']; unset($_SESSION['error']); ?>
                        </div>
                    <?php endif; ?>

                    <form method="POST" action="/contact/send">
                        <div class="mb-3">
                            <label class="form-label">Nome</label>
                            <input type="text" name="name" class="form-control bg-dark text-light border-secondary" required value="<?= htmlspecialchars($_SESSION['old']['name'] ?? ''); unset($_SESSION['old']); ?>">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Email</label>
                            <input type="email" name="email" class="form-control bg-dark text-light border-secondary" required value="<?= htmlspecialchars($_SESSION['old']['email'] ?? ''); ?>">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Mensagem</label>
                            <textarea name="message" class="form-control bg-dark text-light border-secondary" rows="5" required><?= htmlspecialchars($_SESSION['old']['message'] ?? ''); ?></textarea>
                        </div>
                        <div class="text-center">
                            <button type="submit" class="btn btn-danger px-5">Enviar Mensagem</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<?php
$content = ob_get_clean();
require_once __DIR__ . '/../layouts/main.php';

