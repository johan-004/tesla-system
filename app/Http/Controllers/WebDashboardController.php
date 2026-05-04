<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Api\DashboardController as ApiDashboardController;
use Illuminate\Contracts\View\View;

class WebDashboardController extends Controller
{
    public function index(ApiDashboardController $apiDashboardController): View
    {
        $response = $apiDashboardController->resumen();
        $payload = $response->getData(true);

        return view('dashboard', [
            'dashboardData' => $payload['data'] ?? [],
        ]);
    }
}

