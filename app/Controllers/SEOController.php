<?php

namespace App\Controllers;

use App\Services\DatabaseService;

class SEOController extends Controller
{
    private $baseUrl = 'https://motohead.com.br';

    /**
     * GET /sitemap.xml
     * Gera sitemap XML dinâmico com todas as páginas públicas.
     */
    public function sitemap()
    {
        header('Content-Type: application/xml; charset=UTF-8');

        $urls = [];

        // === Páginas estáticas principais ===
        // Apenas páginas que NÃO exigem login (sem requireAuth no controller)
        $staticPages = [
            ['url' => '/', 'priority' => '1.0', 'changefreq' => 'daily'],
            ['url' => '/login', 'priority' => '0.8', 'changefreq' => 'monthly'],
            ['url' => '/register', 'priority' => '0.9', 'changefreq' => 'monthly'],
            ['url' => '/contact', 'priority' => '0.6', 'changefreq' => 'monthly'],
            ['url' => '/lgpd/terms', 'priority' => '0.3', 'changefreq' => 'yearly'],
            ['url' => '/lgpd/privacy', 'priority' => '0.3', 'changefreq' => 'yearly'],
            // gamification, advanced-gamification, clubs/show, events/show, routes/show,
            // feed/show, friends/profile — todos exigem requireAuth, removidos do sitemap
        ];

        foreach ($staticPages as $page) {
            $urls[] = $page;
        }

        // === Páginas dinâmicas do banco ===
        // Todas as páginas dinâmicas (clubs/show, events/show, routes/show, feed/show,
        // friends/profile) exigem requireAuth no controller. Quando o Googlebot as acessa,
        // é redirecionado para /login. Por isso não são incluídas no sitemap.
        // Para reativar, tornar os controllers públicos (remover requireAuth do método show).

        // === Gerar XML ===
        $xml = '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
        $xml .= '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"' . "\n";
        $xml .= '        xmlns:image="http://www.google.com/schemas/sitemap-image/1.1"' . "\n";
        $xml .= '        xmlns:news="http://www.google.com/schemas/sitemap-news/0.9">' . "\n";

        foreach ($urls as $entry) {
            $xml .= "  <url>\n";
            $xml .= "    <loc>" . htmlspecialchars($this->baseUrl . $entry['url']) . "</loc>\n";

            if (!empty($entry['lastmod'])) {
                $date = date('Y-m-d', strtotime($entry['lastmod']));
                $xml .= "    <lastmod>{$date}</lastmod>\n";
            } else {
                $xml .= "    <lastmod>" . date('Y-m-d') . "</lastmod>\n";
            }

            $xml .= "    <changefreq>{$entry['changefreq']}</changefreq>\n";
            $xml .= "    <priority>{$entry['priority']}</priority>\n";
            $xml .= "  </url>\n";
        }

        $xml .= '</urlset>';

        echo $xml;
        exit;
    }

    /**
     * GET /robots.txt — serve o robots.txt dinamicamente (fallback se .htaccess não servir o arquivo estático).
     */
    public function robots()
    {
        header('Content-Type: text/plain; charset=UTF-8');
        $file = __DIR__ . '/../../public/robots.txt';
        if (file_exists($file)) {
            readfile($file);
        } else {
            echo "User-agent: *\nAllow: /\n\nSitemap: " . $this->baseUrl . "/sitemap.xml\n";
        }
        exit;
    }

    /**
     * GET /manifest.json — serve o manifest.json para PWA
     */
    public function manifest()
    {
        header('Content-Type: application/json; charset=UTF-8');
        header('Access-Control-Allow-Origin: *');
        $file = __DIR__ . '/../../public/manifest.json';
        if (file_exists($file)) {
            readfile($file);
        } else {
            echo json_encode([
                'name' => 'MotoHead',
                'short_name' => 'MotoHead',
                'description' => 'A maior comunidade de motociclistas do Brasil',
                'start_url' => '/',
                'display' => 'standalone',
                'background_color' => '#1a1a1a',
                'theme_color' => '#e30613',
                'icons' => [
                    [
                        'src' => '/images/logo.png',
                        'sizes' => '192x192',
                        'type' => 'image/png'
                    ]
                ]
            ]);
        }
        exit;
    }
}
