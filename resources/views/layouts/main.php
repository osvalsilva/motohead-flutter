<?php
// Desabilitar exibição de erros para não quebrar JavaScript
error_reporting(0);
ini_set('display_errors', 0);
?>
<!DOCTYPE html>
<html lang="pt-BR" data-theme="<?= $_SESSION['user_theme'] ?? 'red' ?>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Cache-Control" content="no-store, no-cache, must-revalidate">
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="0">

    <!-- ===== SEO META TAGS ===== -->
    <title><?= htmlspecialchars($title ?? 'MotoHead') ?></title>
    <meta name="description" content="MotoHead — A comunidade dos motociclistas brasileiros. Clubes, eventos, rotas, comboios, gamificação e muito mais.">
    <meta name="keywords" content="motociclistas, clubes de moto, eventos de moto, rotas motociclísticas, comboios, comunidade moto, motociclismo Brasil, MotoHead">
    <meta name="robots" content="<?= $noindex ?? false ? 'noindex, follow' : 'index, follow' ?>">
    <meta name="googlebot" content="<?= $noindex ?? false ? 'noindex, follow' : 'index, follow' ?>">
    <meta name="author" content="MotoHead">
    <meta name="language" content="Portuguese">
    <meta name="geo.region" content="BR">

    <!-- Canonical -->
    <link rel="canonical" href="https://motohead.com.br<?= htmlspecialchars($_SERVER['REQUEST_URI'] ?? '/') ?>">

    <!-- Open Graph -->
    <meta property="og:type" content="website">
    <meta property="og:site_name" content="MotoHead">
    <meta property="og:title" content="<?= htmlspecialchars($title ?? 'MotoHead') ?>">
    <meta property="og:description" content="MotoHead — A comunidade dos motociclistas brasileiros.">
    <meta property="og:url" content="https://motohead.com.br<?= htmlspecialchars($_SERVER['REQUEST_URI'] ?? '/') ?>">
    <meta property="og:image" content="https://motohead.com.br/images/1.jpg">
    <meta property="og:locale" content="pt_BR">

    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary">
    <meta name="twitter:title" content="<?= htmlspecialchars($title ?? 'MotoHead') ?>">
    <meta name="twitter:description" content="MotoHead — A comunidade dos motociclistas brasileiros.">

    <!-- Theme color -->
    <meta name="theme-color" content="#ff0000">

    <!-- Favicon -->
    <link rel="icon" type="image/x-icon" href="/favicon.ico">
    <link rel="apple-touch-icon" href="/images/logo.png">

    <!-- Dados estruturados -->
    <script type="application/ld+json">
    {
        "@context": "https://schema.org",
        "@type": "WebSite",
        "name": "MotoHead",
        "url": "https://motohead.com.br/",
        "inLanguage": "pt-BR"
    }
    </script>

    <script>
    // Aplicar tema salvo antes do CSS renderizar (evita flash)
    (function() {
        var saved = localStorage.getItem('MotoHead_theme');
        if (saved) {
            document.documentElement.setAttribute('data-theme', saved);
        }
    })();
    </script>
    <style>
        /* ===== TEMAS VIA CSS VARIABLES ===== */
        :root,
        [data-theme="red"] {
            --mc-primary: #ff0000;
            --mc-primary-dark: #cc0000;
            --mc-primary-light: #ff3333;
            --mc-primary-rgb: 255, 0, 0;

            /* Cores de fundo (light mode de teste) */
            --mc-bg: #f5f5f5;
            --mc-bg-card: #ffffff;
            --mc-bg-header: #ffffff;
            --mc-bg-sidebar: #5a0a0a;
            --mc-text-sidebar: #ffffff;
            --mc-text-sidebar-muted: #d99;
            --mc-bg-sidebar-hover: #7a1515;
            --mc-bg-footer: #ffffff;
            --mc-bg-hover: #e8e8e8;
            --mc-bg-input: #f0f0f0;
            --mc-border: #ddd;
            --mc-text: #333;
            --mc-text-muted: #666;
            --mc-text-light: #999;
        }

        [data-theme="blue"] {
            --mc-primary: #2196f3;
            --mc-primary-dark: #1976d2;
            --mc-primary-light: #64b5f6;
            --mc-primary-rgb: 33, 150, 243;
        }

        [data-theme="green"] {
            --mc-primary: #4caf50;
            --mc-primary-dark: #388e3c;
            --mc-primary-light: #81c784;
            --mc-primary-rgb: 76, 175, 80;
        }

        [data-theme="purple"] {
            --mc-primary: #9c27b0;
            --mc-primary-dark: #7b1fa2;
            --mc-primary-light: #ba68c8;
            --mc-primary-rgb: 156, 39, 176;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        html, body {
            background: var(--mc-bg);
            color: var(--mc-text);
            font-family: Arial, sans-serif;
            overflow-x: hidden;
        }
        
        body {
            margin: 0;
            padding: 0;
        }
        
        /* Header */
        .top-header {
            width: 100%;
            min-height: 140px;
            background: var(--mc-bg-header);
            border-bottom: 5px solid var(--mc-border);
            padding: 20px 30px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            z-index: 1001;
            flex-wrap: wrap;
            gap: 10px;
        }

        .header-inner {
            width: 100%;
            max-width: 1460px;
            margin: 0;
            padding-left: 30px;
            padding-right: 30px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 10px;
        }
        
        .header-yellow-bar {
            position: absolute;
            bottom: 5px;
            left: 0;
            right: 0;
            height: 5px;
            background: #5a0a0a;
            z-index: 1002;
        }
        
        .logo-link {
            display: inline-block;
        }
        
        .header-logo {
            height: 100px;
            width: auto;
            max-width: 100%;
            display: block;
        }
        
        .header-right {
            display: flex;
            align-items: center;
            gap: 15px;
            flex-wrap: wrap;
        }
        
        .header-user {
            display: flex;
            flex-direction: column;
            align-items: flex-end;
        }
        
        .header-user-name {
            color: var(--mc-text);
            font-size: 14px;
            font-weight: bold;
        }

        .header-user-role {
            color: var(--mc-primary);
            font-size: 12px;
        }
        
        .header-logout {
            white-space: nowrap;
        }

        .header-edit-profile {
            background: transparent;
            color: var(--mc-text);
            border: 1px solid var(--mc-border);
            padding: 6px 16px;
            font-size: 13px;
            border-radius: 6px;
            text-decoration: none;
            white-space: nowrap;
            transition: all 0.2s;
        }

        .header-edit-profile:hover {
            border-color: var(--mc-primary);
            color: var(--mc-primary);
        }
        
        /* Sidebar */
        .sidebar {
            width: 250px;
            position: fixed;
            left: 0;
            top: 140px;
            bottom: 0;
            background: var(--mc-bg-sidebar);
            border-right: 1px solid var(--mc-border);
            overflow-y: scroll;
            scrollbar-width: none;
            -ms-overflow-style: none;
            box-shadow: 4px 0 12px rgba(0,0,0,0.3);
            z-index: 1000;
        }

        .sidebar::-webkit-scrollbar {
            display: none;
        }
        
        .sidebar-menu {
            padding: 10px 0;
        }
        
        .sidebar-menu a {
            display: block;
            padding: 12px 20px;
            color: #ffffff;
            text-decoration: none;
            border-left: 3px solid transparent;
            font-size: 14px;
            border-bottom: 1px solid rgba(255, 0, 0, 0.08);
        }

        .sidebar-menu a:hover {
            background: var(--mc-bg-sidebar-hover);
            color: #ff9999;
            border-left-color: var(--mc-primary);
        }

        .sidebar-menu a.active {
            background: var(--mc-bg-sidebar-hover);
            color: var(--mc-primary);
            border-left-color: var(--mc-primary);
        }
        
        .sidebar-menu a span {
            margin-right: 10px;
        }

        /* Notification badge */
        .notif-badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 18px;
            height: 18px;
            padding: 0 5px;
            background: #ff0000;
            color: #fff;
            font-size: 10px;
            font-weight: bold;
            border-radius: 9px;
            margin-left: auto;
            line-height: 1;
            box-shadow: 0 0 6px rgba(255, 0, 0, 0.6);
            animation: badge-pulse 2s ease-in-out infinite;
        }
        @keyframes badge-pulse {
            0%, 100% { box-shadow: 0 0 6px rgba(255, 0, 0, 0.6); }
            50% { box-shadow: 0 0 12px rgba(255, 0, 0, 0.9); }
        }
        .sidebar-menu a {
            display: flex;
            align-items: center;
        }
        
        /* Main content */
        .main-content {
            margin-left: 250px;
            margin-top: 140px;
            background: var(--mc-bg);
            min-height: calc(100vh - 140px);
            display: flex;
            flex-direction: column;
            align-items: flex-start;
        }

        .container {
            max-width: 1200px;
            width: 100%;
            margin: 0;
            padding: 20px 20px 40px 20px;
            flex: 1;
        }

        /* ===== WIDGETS ===== */
        .widget-header-banner {
            width: 100%;
            max-width: 1200px;
            margin: 0 auto;
            padding: 10px 20px 0 20px;
        }
        .widget-header-banner-inner {
            background: var(--mc-bg-card);
            border: 1px solid var(--mc-border);
            border-radius: 8px;
            overflow: hidden;
            text-align: center;
        }
        .widget-header-banner-inner img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 0 auto;
        }
        .widget-header-banner-inner a {
            display: block;
            text-decoration: none;
        }

        .widget-layout-row {
            display: flex;
            gap: 20px;
            width: 100%;
            max-width: 1200px;
            margin: 0;
            padding: 0 20px;
        }
        .widget-layout-main {
            flex: 1;
            min-width: 0;
        }
        .widget-middle-banner {
            margin-bottom: 20px;
        }
        .widget-middle-banner-inner {
            background: var(--mc-bg-card);
            border: 1px solid var(--mc-border);
            border-radius: 8px;
            overflow: hidden;
            text-align: center;
        }
        .widget-middle-banner-inner img {
            max-width: 100%;
            height: auto;
            display: block;
        }
        .widget-middle-banner-inner a {
            display: block;
            text-decoration: none;
        }

        .widget-right-sidebar {
            width: 280px;
            flex-shrink: 0;
        }
        .widget-right-card {
            background: var(--mc-bg-card);
            border: 1px solid var(--mc-border);
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 15px;
            text-decoration: none;
            display: block;
            transition: box-shadow 0.2s;
        }
        .widget-right-card:hover {
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .widget-right-card-icon {
            font-size: 28px;
            margin-bottom: 8px;
        }
        .widget-right-card-title {
            color: var(--mc-text);
            font-weight: bold;
            font-size: 14px;
            margin-bottom: 5px;
        }
        .widget-right-card-text {
            color: var(--mc-text-muted);
            font-size: 12px;
            line-height: 1.5;
        }

        .widget-bottom-banner {
            width: 100%;
            max-width: 1200px;
            margin: 20px auto 0 auto;
            padding: 0 20px;
        }
        .widget-bottom-banner-inner {
            background: var(--mc-bg-card);
            border: 1px solid var(--mc-border);
            border-radius: 8px;
            overflow: hidden;
            text-align: center;
        }
        .widget-bottom-banner-inner img {
            max-width: 100%;
            height: auto;
            display: block;
        }
        .widget-bottom-banner-inner a {
            display: block;
            text-decoration: none;
        }

        @media (max-width: 900px) {
            .widget-layout-row {
                flex-direction: column;
            }
            .widget-right-sidebar {
                width: 100%;
            }
        }
        
        /* Page header */
        .page-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 30px;
            padding-bottom: 15px;
            border-bottom: 1px solid #222;
            flex-wrap: wrap;
            gap: 10px;
        }
        
        .page-header h2 {
            color: var(--mc-text);
            margin: 0;
        }
        
        /* Footer */
        .site-footer {
            width: 100%;
            background: var(--mc-bg-footer);
            border-top: 1px solid var(--mc-border);
            padding: 20px 30px;
            text-align: center;
            margin-top: auto;
        }

        .site-footer p {
            color: var(--mc-text-light);
            font-size: 12px;
        }
        
        /* Cards */
        .card {
            background: var(--mc-bg-card);
            border: 1px solid var(--mc-border);
            border-radius: 16px;
            padding: 20px;
            margin-bottom: 20px;
            overflow-wrap: break-word;
            word-wrap: break-word;
        }
        
        .card h2, .card h3, .card h1 {
            color: var(--mc-text);
            margin-top: 0;
            border-bottom: 1px solid var(--mc-border);
            padding-bottom: 10px;
        }

        /* Buttons */
        .btn {
            padding: 10px 20px;
            border: 1px solid var(--mc-border);
            border-radius: 4px;
            cursor: pointer;
            background: var(--mc-bg-hover);
            color: var(--mc-text);
            font-weight: bold;
            text-transform: uppercase;
            white-space: nowrap;
        }

        .btn:hover {
            background: var(--mc-bg-input);
            border-color: var(--mc-primary);
        }

        .btn-delete {
            background: var(--mc-bg-hover);
            border: 1px solid var(--mc-primary-dark);
            color: var(--mc-primary-dark);
        }

        .btn-delete:hover {
            background: var(--mc-bg-input);
        }

        /* Follow buttons */
        .btn-follow {
            background: var(--mc-primary);
            border: 1px solid var(--mc-primary);
            color: #fff;
        }

        .btn-follow:hover {
            background: var(--mc-primary-dark);
            border-color: var(--mc-primary-dark);
        }

        .btn-following {
            background: var(--mc-bg-hover);
            border: 1px solid var(--mc-border);
            color: var(--mc-text-muted);
        }

        .btn-following:hover {
            background: var(--mc-bg-input);
            border-color: var(--mc-primary);
            color: var(--mc-text);
        }

        /* Form elements */
        input, select, textarea {
            width: 100%;
            padding: 10px;
            background: var(--mc-bg-input);
            border: 1px solid var(--mc-border);
            color: var(--mc-text);
            border-radius: 4px;
            max-width: 100%;
        }
        
        input[type="file"] {
            padding: 5px;
        }
        
        input[type="checkbox"], input[type="radio"] {
            width: auto;
        }
        
        /* Tables - responsive */
        .table-responsive {
            overflow-x: auto;
            -webkit-overflow-scrolling: touch;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            background: var(--mc-bg-card);
            min-width: 600px;
        }

        table th {
            background: var(--mc-bg-hover);
            color: var(--mc-text);
            padding: 12px;
            text-align: left;
            border-bottom: 2px solid var(--mc-border);
        }

        table td {
            background: var(--mc-bg-card);
            color: var(--mc-text-muted);
            padding: 12px;
            border-bottom: 1px solid var(--mc-border);
        }
        
        /* Links */
        a {
            color: var(--mc-primary);
            text-decoration: none;
        }
        
        a:hover {
            color: #cc0000;
        }
        
        /* Images responsive */
        img {
            max-width: 100%;
            height: auto;
        }
        
        /* Grid responsive helper - only override fixed-width column grids on mobile */
        @media (max-width: 768px) {
            [style*="grid-template-columns: 300px 1fr"],
            [style*="grid-template-columns: 280px 1fr"],
            [style*="grid-template-columns: 250px 1fr"],
            [style*="grid-template-columns: 200px 1fr"],
            [style*="grid-template-columns: 320px 1fr"],
            [style*="grid-template-columns: 1fr 1fr"],
            [style*="grid-template-columns: 1fr 1fr 1fr"],
            [style*="grid-template-columns: 1fr 1fr 1fr 1fr"],
            [style*="grid-template-columns: 1fr 250px"] {
                grid-template-columns: 1fr !important;
            }
            #feed-sidebar-right { display: none !important; }
        }
        
        /* Flex wrap helper */
        [style*="display: flex"]:not(#stories-track) {
            flex-wrap: wrap;
        }
        
        /* Mobile menu toggle */
        .mobile-menu-toggle {
            display: none;
            position: fixed;
            top: 150px;
            left: 15px;
            z-index: 1002;
            background: var(--mc-bg-hover);
            color: var(--mc-text);
            border: 1px solid var(--mc-primary);
            padding: 10px 15px;
            border-radius: 4px;
            cursor: pointer;
        }
        
        /* ===== RESPONSIVE BREAKPOINTS ===== */
        
        /* Tablet */
        @media (max-width: 1024px) {
            .container {
                padding: 15px 20px 80px 20px;
            }
            
            .top-header {
                padding: 15px 20px;
            }
            
            .header-logo {
                height: 80px;
            }
        }
        
        /* Mobile */
        @media (max-width: 768px) {
            .mobile-menu-toggle {
                display: block;
            }
            
            .sidebar {
                transform: translateX(-100%);
                transition: transform 0.3s ease;
                width: 250px;
                top: 140px;
                bottom: 60px;
            }
            
            .sidebar.active {
                transform: translateX(0);
            }
            
            .main-content {
                margin-left: 0;
            }
            
            .top-header {
                height: auto;
                min-height: 100px;
                padding: 10px 15px;
            }

            .header-inner {
                padding-left: 15px;
                padding-right: 15px;
                flex-direction: column;
                align-items: flex-start;
            }
            
            .header-logo {
                height: 60px;
            }
            
            .header-right {
                width: 100%;
                justify-content: space-between;
            }
            
            .header-user {
                align-items: flex-start;
            }
            
            .main-content {
                margin-top: 100px;
            }
            
            .container {
                padding: 15px 15px 80px 15px;
            }
            
            .page-header {
                flex-direction: column;
                align-items: flex-start;
                gap: 10px;
            }
            
            .page-header h2 {
                font-size: 18px;
            }
            
            .card {
                padding: 15px;
            }
            
            .btn {
                padding: 8px 14px;
                font-size: 12px;
            }
            
            .site-footer {
                padding: 15px;
                height: auto;
                min-height: 50px;
            }
            
            .mobile-menu-toggle {
                top: 105px;
            }
            
            /* Table responsive on mobile */
            table {
                display: block;
                overflow-x: auto;
                -webkit-overflow-scrolling: touch;
            }
            
            /* Force flex layouts to stack */
            [style*="display: flex"][style*="gap: 10px"]:not(#stories-track),
            [style*="display: flex"][style*="gap: 15px"]:not(#stories-track),
            [style*="display: flex"][style*="gap: 20px"]:not(#stories-track) {
                flex-direction: column !important;
            }
        }
        
        /* Small mobile */
        @media (max-width: 480px) {
            .container {
                padding: 10px 10px 80px 10px;
            }
            
            .card {
                padding: 12px;
                margin-bottom: 15px;
            }
            
            .page-header h2 {
                font-size: 16px;
            }
            
            .header-logo {
                height: 50px;
            }
            
            .header-user-name {
                font-size: 12px;
            }
            
            .header-user-role {
                font-size: 10px;
            }
            
            .btn {
                padding: 7px 12px;
                font-size: 11px;
            }
            
            table {
                min-width: 400px;
            }
        }
    </style>
</head>
<body>
    <?php
    // Buscar contagem de notificações não lidas
    $notifCount = 0;
    try {
        if (isset($_SESSION['user_id'])) {
            $notifModel = new \App\Models\Notification();
            $notifCount = $notifModel->countUnread($_SESSION['user_id']);
        }
    } catch (\Exception $e) {
        $notifCount = 0;
    }
    ?>
    <?php require_once __DIR__ . '/../partials/header.php'; ?>
    <?php require_once __DIR__ . '/../partials/sidebar.php'; ?>

    <?php
    // ===== SISTEMA DE WIDGETS =====
    $currentPath = $_SERVER['REQUEST_URI'] ?? '/';
    // Remove query string
    $currentPath = strpos($currentPath, '?') !== false ? substr($currentPath, 0, strpos($currentPath, '?')) : $currentPath;

    $widgetModel = null;
    $widgetSettings = [];
    $headerWidgets = [];
    $rightWidgets = [];
    $middleWidgets = [];
    $bottomWidgets = [];

    try {
        $widgetModel = new \App\Models\Widget();
        $widgetSettings = $widgetModel->getAllSettings();

        if ($widgetSettings['header_banner'] ?? false) {
            $headerWidgets = $widgetModel->getActiveByPosition('header_banner', $currentPath);
        }
        if ($widgetSettings['right_sidebar'] ?? false) {
            $rightWidgets = $widgetModel->getActiveByPosition('right_sidebar', $currentPath);
        }
        if ($widgetSettings['middle_banner'] ?? false) {
            $middleWidgets = $widgetModel->getActiveByPosition('middle_banner', $currentPath);
        }
        if ($widgetSettings['bottom_banner'] ?? false) {
            $bottomWidgets = $widgetModel->getActiveByPosition('bottom_banner', $currentPath);
        }
    } catch (\Exception $e) {
        // Tabela pode nao existir ainda - silencioso
    }

    $hasRightSidebar = !empty($rightWidgets);
    $hasMiddleBanner = !empty($middleWidgets);
    ?>

    <div class="main-content">
        <!-- Widget 1: Banner do Header -->
        <?php if (!empty($headerWidgets)): ?>
        <div class="widget-header-banner">
            <?php foreach ($headerWidgets as $hw): ?>
                <div class="widget-header-banner-inner">
                    <?php if (!empty($hw['html_content'])): ?>
                        <?= $hw['html_content'] ?>
                    <?php elseif (!empty($hw['image_url'])): ?>
                        <?php if (!empty($hw['link_url'])): ?>
                            <a href="<?= htmlspecialchars($hw['link_url']) ?>" target="_blank" rel="noopener">
                                <img src="<?= htmlspecialchars($hw['image_url']) ?>" alt="<?= htmlspecialchars($hw['title'] ?? 'Banner') ?>">
                            </a>
                        <?php else: ?>
                            <img src="<?= htmlspecialchars($hw['image_url']) ?>" alt="<?= htmlspecialchars($hw['title'] ?? 'Banner') ?>">
                        <?php endif; ?>
                    <?php elseif (!empty($hw['content'])): ?>
                        <div style="padding: 15px; color: var(--mc-text);"><?= htmlspecialchars($hw['content']) ?></div>
                    <?php endif; ?>
                </div>
            <?php endforeach; ?>
        </div>
        <?php endif; ?>

        <div class="widget-layout-row">
            <div class="widget-layout-main">
                <!-- Widget 3: Banner Central (antes do conteudo) -->
                <?php if (!empty($middleWidgets)): ?>
                <div class="widget-middle-banner">
                    <?php foreach ($middleWidgets as $mw): ?>
                        <div class="widget-middle-banner-inner">
                            <?php if (!empty($mw['html_content'])): ?>
                                <?= $mw['html_content'] ?>
                            <?php elseif (!empty($mw['image_url'])): ?>
                                <?php if (!empty($mw['link_url'])): ?>
                                    <a href="<?= htmlspecialchars($mw['link_url']) ?>" target="_blank" rel="noopener">
                                        <img src="<?= htmlspecialchars($mw['image_url']) ?>" alt="<?= htmlspecialchars($mw['title'] ?? 'Banner') ?>">
                                    </a>
                                <?php else: ?>
                                    <img src="<?= htmlspecialchars($mw['image_url']) ?>" alt="<?= htmlspecialchars($mw['title'] ?? 'Banner') ?>">
                                <?php endif; ?>
                            <?php elseif (!empty($mw['content'])): ?>
                                <div style="padding: 15px; color: var(--mc-text);"><?= htmlspecialchars($mw['content']) ?></div>
                            <?php endif; ?>
                        </div>
                    <?php endforeach; ?>
                </div>
                <?php endif; ?>

                <!-- Conteudo principal da pagina -->
                <div class="container">
                    <?= $content ?>
                </div>

                <!-- Widget 4: Banner Inferior (depois do conteudo) -->
                <?php if (!empty($bottomWidgets)): ?>
                <div class="widget-bottom-banner">
                    <?php foreach ($bottomWidgets as $bw): ?>
                        <div class="widget-bottom-banner-inner">
                            <?php if (!empty($bw['html_content'])): ?>
                                <?= $bw['html_content'] ?>
                            <?php elseif (!empty($bw['image_url'])): ?>
                                <?php if (!empty($bw['link_url'])): ?>
                                    <a href="<?= htmlspecialchars($bw['link_url']) ?>" target="_blank" rel="noopener">
                                        <img src="<?= htmlspecialchars($bw['image_url']) ?>" alt="<?= htmlspecialchars($bw['title'] ?? 'Banner') ?>">
                                    </a>
                                <?php else: ?>
                                    <img src="<?= htmlspecialchars($bw['image_url']) ?>" alt="<?= htmlspecialchars($bw['title'] ?? 'Banner') ?>">
                                <?php endif; ?>
                            <?php elseif (!empty($bw['content'])): ?>
                                <div style="padding: 15px; color: var(--mc-text);"><?= htmlspecialchars($bw['content']) ?></div>
                            <?php endif; ?>
                        </div>
                    <?php endforeach; ?>
                </div>
                <?php endif; ?>
            </div>

            <!-- Widget 2: Lateral Direita (Cards) -->
            <?php if ($hasRightSidebar): ?>
            <div class="widget-right-sidebar">
                <?php foreach ($rightWidgets as $rw): ?>
                    <?php
                    $cardHref = !empty($rw['card_link']) ? htmlspecialchars($rw['card_link']) : '#';
                    $isLink = !empty($rw['card_link']);
                    ?>
                    <?php if ($isLink): ?>
                        <a href="<?= $cardHref ?>" class="widget-right-card">
                    <?php else: ?>
                        <div class="widget-right-card">
                    <?php endif; ?>
                        <?php if (!empty($rw['html_content'])): ?>
                            <?= $rw['html_content'] ?>
                        <?php else: ?>
                            <?php if (!empty($rw['card_icon'])): ?>
                                <div class="widget-right-card-icon"><?= htmlspecialchars($rw['card_icon']) ?></div>
                            <?php endif; ?>
                            <?php if (!empty($rw['card_title'])): ?>
                                <div class="widget-right-card-title"><?= htmlspecialchars($rw['card_title']) ?></div>
                            <?php elseif (!empty($rw['title'])): ?>
                                <div class="widget-right-card-title"><?= htmlspecialchars($rw['title']) ?></div>
                            <?php endif; ?>
                            <?php if (!empty($rw['card_text'])): ?>
                                <div class="widget-right-card-text"><?= htmlspecialchars($rw['card_text']) ?></div>
                            <?php elseif (!empty($rw['content'])): ?>
                                <div class="widget-right-card-text"><?= htmlspecialchars($rw['content']) ?></div>
                            <?php endif; ?>
                        <?php endif; ?>
                    <?php if ($isLink): ?>
                        </a>
                    <?php else: ?>
                        </div>
                    <?php endif; ?>
                <?php endforeach; ?>
            </div>
            <?php endif; ?>
        </div>

        <?php require_once __DIR__ . '/../partials/footer.php'; ?>
    </div>
    <script src="/assets/js/custom-dialogs.js"></script>
    <script src="/js/custom-modal.js"></script>
    <script src="/js/photo-crop.js"></script>

    <!-- Modal de Segurança -->
    <div id="security-modal" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.85); z-index: 9999; overflow-y: auto;">
        <div style="max-width: 600px; margin: 50px auto; background: #111; border: 1px solid #333; border-radius: 8px; padding: 30px;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                <h2 style="color: #ccc; margin: 0;">🛡️ Segurança</h2>
                <button type="button" onclick="closeSecurityModal()" style="background: none; border: none; color: #fff; font-size: 28px; cursor: pointer;">×</button>
            </div>
            
            <div style="margin-bottom: 20px;">
                <a href="/emergency" class="btn" style="width: 100%; display: block; text-align: center; padding: 15px;">📢 Gerenciar Segurança</a>
            </div>
            
            <div style="background: #1a1a1a; padding: 15px; border-radius: 4px; margin-bottom: 15px;">
                <h4 style="color: #ccc; margin-bottom: 10px;">🆘 Alerta Rápido</h4>
                <form method="POST" action="/emergency/trigger-panic" onsubmit="triggerQuickPanic(this); return false;">
                    <?php use App\Middleware\CsrfMiddleware; ?>
                    <?= CsrfMiddleware::field() ?>
                    <input type="hidden" name="type" value="panic">
                    <input type="hidden" name="latitude" id="quick-panic-lat">
                    <input type="hidden" name="longitude" id="quick-panic-lng">
                    <button type="submit" class="btn btn-delete" style="width: 100%;">🚨 ATIVAR PÂNICO</button>
                </form>
            </div>
            
            <div style="background: #1a1a1a; padding: 15px; border-radius: 4px;">
                <h4 style="color: #ccc; margin-bottom: 10px;">📍Localização em Tempo Real</h4>
                <p style="color: #888; font-size: 13px; margin-bottom: 10px;">Ative para permitir que seus contatos e motociclistas próximos vejam sua localização em emergências.</p>
                <label style="display: flex; align-items: center; gap: 10px;">
                    <input type="checkbox" id="realtime-location" onchange="toggleRealtimeLocation()">
                    <span style="color: #ccc; font-size: 14px;">Ativar localização em tempo real</span>
                </label>
            </div>
        </div>
    </div>

    <!-- Botão de Pânico Flutuante -->
    <button id="panic-button" onclick="openSecurityModal()" style="position: fixed; bottom: 80px; right: 30px; width: 70px; height: 70px; border-radius: 50%; background: linear-gradient(135deg, #8B0000 0%, #DC143C 100%); border: 3px solid #fff; color: #fff; font-size: 32px; cursor: pointer; z-index: 9998; box-shadow: 0 4px 15px rgba(220, 20, 60, 0.5); transition: transform 0.2s;" onmouseover="this.style.transform='scale(1.1)'" onmouseout="this.style.transform='scale(1)'">
        🆘
    </button>

    <script>
    function openSecurityModal() {
        document.getElementById('security-modal').style.display = 'block';
    }

    function closeSecurityModal() {
        document.getElementById('security-modal').style.display = 'none';
    }

    function triggerQuickPanic(form) {
        CustomModal.confirm('ATENÇÃO: Isso enviará um alerta de PÂNICO para seus contatos e motociclistas próximos. Deseja continuar?', function(){
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(function(position) {
                    document.getElementById('quick-panic-lat').value = position.coords.latitude;
                    document.getElementById('quick-panic-lng').value = position.coords.longitude;
                    form.submit();
                }, function(error) {
                    form.submit();
                });
            } else {
                form.submit();
            }
        });
    }

    function toggleRealtimeLocation() {
        const checkbox = document.getElementById('realtime-location');
        if (checkbox.checked) {
            CustomModal.alert('Localização em tempo real ativada. Sua posição será compartilhada em emergências.');
        } else {
            CustomModal.alert('Localização em tempo real desativada.');
        }
    }

    document.getElementById('security-modal').addEventListener('click', function(e) {
        if (e.target === this) {
            closeSecurityModal();
        }
    });
    </script>
    <script src="/assets/js/error-logger.js"></script>
    <!-- Cropper.js para recorte de imagens -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.2/cropper.min.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.2/cropper.min.js"></script>
    <!-- DEBUG: Versão <?= date('Y-m-d H:i:s') ?> | Emoji test: 🏍️🔴📋📅🏆🔧⛽💰🧤📖💬 -->
</body>
</html>
