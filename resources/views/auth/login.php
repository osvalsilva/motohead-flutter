<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="robots" content="noindex, follow">
    <title><?= $title ?></title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        html, body {
            background: #000;
            color: #ccc;
            font-family: Arial, sans-serif;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .main-content {
            width: 100%;
            max-width: 400px;
            padding: 20px;
        }
        
        .container {
            background: #111;
            border: 1px solid #222;
            padding: 40px;
            border-radius: 8px;
        }
        
        h1 {
            color: #ff0000;
            text-align: center;
            margin-bottom: 30px;
            text-transform: uppercase;
            font-size: 24px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        label {
            display: block;
            color: #888;
            margin-bottom: 8px;
            font-size: 14px;
            text-transform: uppercase;
        }
        
        input {
            width: 100%;
            padding: 12px;
            background: #1a1a1a;
            border: 1px solid #222;
            color: #ccc;
            border-radius: 4px;
            font-size: 14px;
        }
        
        input:focus {
            outline: none;
            border-color: #ff0000;
        }
        
        .btn {
            width: 100%;
            padding: 12px;
            background: #ff0000;
            color: #fff;
            border: none;
            border-radius: 4px;
            font-size: 16px;
            font-weight: bold;
            text-transform: uppercase;
            cursor: pointer;
        }
        
        .btn:hover {
            background: #cc0000;
        }
        
        .links {
            text-align: center;
            margin-top: 20px;
        }
        
        .links a {
            color: #ff0000;
            text-decoration: none;
        }
        
        .links a:hover {
            color: #cc0000;
        }
        
        .error {
            color: #ff0000;
            font-size: 12px;
            margin-top: 5px;
        }
    </style>
</head>
<body>
    <div class="main-content">
    <div class="container">
        <h1>Login</h1>
        <form method="POST" action="/login">
        <?php use App\Middleware\CsrfMiddleware; ?>
        <?= CsrfMiddleware::field() ?>
            <div class="form-group">
                <label for="email">Email:</label>
                <input type="email" id="email" name="email" value="<?= $old['email'] ?? '' ?>" required>
                <?php if (isset($errors['email'])): ?>
                    <div class="error"><?= $errors['email'] ?></div>
                <?php endif; ?>
            </div>
            
            <div class="form-group">
                <label for="password">Senha:</label>
                <input type="password" id="password" name="password" required>
                <?php if (isset($errors['password'])): ?>
                    <div class="error"><?= $errors['password'] ?></div>
                <?php endif; ?>
            </div>
            
            <button type="submit" class="btn">Entrar</button>
        </form>
        
        <div class="links">
            <p><a href="/forgot-password">Esqueci minha senha</a></p>
            <p>Não tem uma conta? <a href="/register">Registre-se</a></p>
        </div>
    </div>
</body>
</html>
