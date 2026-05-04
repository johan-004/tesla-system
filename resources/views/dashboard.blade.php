<x-app-layout>
    @php
        $business = $dashboardData['business_dashboard'] ?? [];
        $periodo = $business['periodo'] ?? [];
        $kpis = $business['kpis'] ?? [];
        $graficas = $business['graficas'] ?? [];
        $topItems = $business['top_items_vendidos'] ?? [];
        $estadoDocumentos = $business['estado_documentos'] ?? [];
        $resumenFinanciero = $business['resumen_financiero'] ?? [];

        $filtro = $dashboardData['contexto']['filtro_dashboard'] ?? [];
        $mesSeleccionado = (int) ($filtro['mes'] ?? now()->month);
        $anioSeleccionado = (int) ($filtro['anio'] ?? now()->year);
        $userLabel = trim((string) (auth()->user()->name ?? 'Admin Tesla'));

        $kpiCards = [
            [
                'title' => 'Ventas (Facturas)',
                'icon' => '💲',
                'bg' => 'bg-emerald-50',
                'value' => (float) (($kpis['ventas_facturas']['valor'] ?? 0)),
                'variation' => (float) (($kpis['ventas_facturas']['variacion_pct'] ?? 0)),
                'money' => true,
            ],
            [
                'title' => 'Facturas emitidas',
                'icon' => '📄',
                'bg' => 'bg-blue-50',
                'value' => (float) (($kpis['facturas_emitidas']['valor'] ?? 0)),
                'variation' => (float) (($kpis['facturas_emitidas']['variacion_pct'] ?? 0)),
                'money' => false,
            ],
            [
                'title' => 'Cotizaciones enviadas',
                'icon' => '🧾',
                'bg' => 'bg-violet-50',
                'value' => (float) (($kpis['cotizaciones_enviadas']['valor'] ?? 0)),
                'variation' => (float) (($kpis['cotizaciones_enviadas']['variacion_pct'] ?? 0)),
                'money' => false,
            ],
            [
                'title' => 'Productos vendidos',
                'icon' => '📦',
                'bg' => 'bg-orange-50',
                'value' => (float) (($kpis['productos_vendidos']['valor'] ?? 0)),
                'variation' => (float) (($kpis['productos_vendidos']['variacion_pct'] ?? 0)),
                'money' => false,
            ],
            [
                'title' => 'Servicios facturados',
                'icon' => '🛠️',
                'bg' => 'bg-fuchsia-50',
                'value' => (float) (($kpis['servicios_facturados']['valor'] ?? 0)),
                'variation' => (float) (($kpis['servicios_facturados']['variacion_pct'] ?? 0)),
                'money' => false,
            ],
        ];

        $monthNames = [
            1 => 'Enero', 2 => 'Febrero', 3 => 'Marzo', 4 => 'Abril', 5 => 'Mayo', 6 => 'Junio',
            7 => 'Julio', 8 => 'Agosto', 9 => 'Septiembre', 10 => 'Octubre', 11 => 'Noviembre', 12 => 'Diciembre',
        ];
    @endphp

    <div class="bg-[#f5f7fb] py-6">
        <div class="mx-auto w-full max-w-[1450px] space-y-4 px-4 sm:px-6 lg:px-8">
            <section class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
                <div class="flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
                    <div>
                        <h1 class="text-5xl font-extrabold leading-none text-[#17264a]">Dashboard</h1>
                        <p class="mt-2 text-[30px] text-[#6a7a97]">Resumen general de tu negocio en tiempo real.</p>
                    </div>
                    <div class="flex items-center gap-3 rounded-xl border border-slate-200 bg-white px-3 py-2">
                        <div class="relative">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-[#1d2f57]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M14.857 17H9.143m10.714 0H4.143m15.714 0a2.143 2.143 0 0 1-2.143 2.143H6.286A2.143 2.143 0 0 1 4.143 17m15.714 0V11a7.857 7.857 0 0 0-15.714 0v6m13.571 0H6.286" />
                            </svg>
                            <span class="absolute -right-1.5 -top-1.5 inline-flex h-4 min-w-4 items-center justify-center rounded-full bg-rose-500 px-1 text-[10px] font-bold text-white">3</span>
                        </div>
                        <div class="text-right">
                            <p class="text-sm font-bold text-[#1d2f57]">{{ $userLabel }}</p>
                            <p class="text-xs text-[#6a7a97]">Administrador</p>
                        </div>
                        <div class="h-8 w-8 rounded-full bg-emerald-500/20 ring-2 ring-emerald-500/70"></div>
                    </div>
                </div>

                <div class="mt-4">
                    <form method="GET" class="grid w-full gap-2 sm:grid-cols-2 xl:ml-auto xl:w-fit xl:grid-cols-4">
                        <div class="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-semibold text-[#1d2f57] sm:col-span-2 xl:min-w-[290px]">
                            {{ ($periodo['inicio'] ?? '-') . ' - ' . ($periodo['fin'] ?? '-') }}
                        </div>

                        <select name="mes" class="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-semibold text-[#1d2f57]">
                            @foreach ($monthNames as $index => $name)
                                <option value="{{ $index }}" @selected($mesSeleccionado === $index)>Mes: {{ $name }}</option>
                            @endforeach
                        </select>

                        <select name="anio" class="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-semibold text-[#1d2f57]">
                            @foreach (($dashboardData['contexto']['anios_disponibles'] ?? [now()->year]) as $year)
                                <option value="{{ (int) $year }}" @selected($anioSeleccionado === (int) $year)>Año: {{ (int) $year }}</option>
                            @endforeach
                        </select>

                        <button class="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-bold text-[#1d2f57] hover:bg-slate-50">
                            Actualizar
                        </button>
                    </form>
                </div>
            </section>

            <section class="grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
                @foreach ($kpiCards as $card)
                    <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
                        <div class="flex items-start gap-3">
                            <div class="{{ $card['bg'] }} flex h-11 w-11 items-center justify-center rounded-xl text-xl">{{ $card['icon'] }}</div>
                            <div>
                                <p class="text-sm font-semibold text-slate-600">{{ $card['title'] }}</p>
                                <p class="mt-1 text-[42px] font-extrabold leading-none text-[#17264a]">
                                    {{ $card['money'] ? '$' . number_format($card['value'], 0, ',', '.') : number_format($card['value'], 0, ',', '.') }}
                                </p>
                                <p class="mt-1 text-sm font-semibold {{ $card['variation'] < 0 ? 'text-rose-600' : 'text-emerald-600' }}">
                                    @if ($card['variation'] == 0)
                                        Sin comparación
                                    @else
                                        {{ $card['variation'] < 0 ? '↓' : '↑' }} {{ number_format(abs($card['variation']), 1, ',', '.') }}% vs periodo anterior
                                    @endif
                                </p>
                            </div>
                        </div>
                    </article>
                @endforeach
            </section>

            <section class="grid gap-4 xl:grid-cols-2">
                <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
                    <div class="mb-3 flex items-center justify-between">
                        <div>
                            <h2 class="text-2xl font-extrabold text-slate-900">Ventas diarias (Este mes)</h2>
                            <p class="text-slate-500">Total: <span id="dailyTotal" class="font-semibold text-slate-700">$0</span></p>
                        </div>
                        <div class="flex items-center gap-2">
                            <span class="rounded-lg border border-slate-200 px-3 py-1 text-sm font-semibold text-slate-600">Lineal</span>
                            <button type="button" data-expand-chart="daily" class="rounded-lg border border-slate-200 px-3 py-1 text-sm font-semibold text-slate-600">Ampliar</button>
                        </div>
                    </div>
                    <div class="relative h-[320px]">
                        <canvas id="dailySalesChart" class="h-full w-full"></canvas>
                        <div id="dailyEmpty" class="absolute inset-0 hidden items-center justify-center rounded-xl border border-slate-200 bg-slate-50 text-slate-500">Aún no hay ventas en este periodo.</div>
                    </div>
                </article>

                <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
                    <div class="mb-3 flex items-center justify-between">
                        <div>
                            <h2 class="text-2xl font-extrabold text-slate-900">Ventas por mes (Este año)</h2>
                            <p class="text-slate-500">Total anual: <span id="yearlyTotal" class="font-semibold text-slate-700">$0</span></p>
                        </div>
                        <div class="flex items-center gap-2">
                            <span class="rounded-lg border border-slate-200 px-3 py-1 text-sm font-semibold text-slate-600">Barras</span>
                            <button type="button" data-expand-chart="yearly" class="rounded-lg border border-slate-200 px-3 py-1 text-sm font-semibold text-slate-600">Ampliar</button>
                        </div>
                    </div>
                    <div class="relative h-[320px]">
                        <canvas id="yearlySalesChart" class="h-full w-full"></canvas>
                        <div id="yearlyEmpty" class="absolute inset-0 hidden items-center justify-center rounded-xl border border-slate-200 bg-slate-50 text-slate-500">Aún no hay ventas registradas en este año.</div>
                    </div>
                </article>
            </section>

            <section class="grid gap-4 xl:grid-cols-3">
                <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
                    <h3 class="text-2xl font-extrabold text-slate-900">Ventas por categoría (Productos)</h3>
                    <div class="mt-3 grid gap-3 sm:grid-cols-2 xl:grid-cols-1">
                        <div class="relative h-[220px]">
                            <canvas id="categoryChart"></canvas>
                            <div id="categoryEmpty" class="absolute inset-0 hidden items-center justify-center rounded-xl border border-slate-200 bg-slate-50 p-4 text-center text-slate-500">Aún no hay productos vendidos en este periodo.</div>
                        </div>
                        <div id="categoryLegend" class="space-y-2 text-sm"></div>
                    </div>
                </article>

                <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
                    <h3 class="text-2xl font-extrabold text-slate-900">Ventas por tipo</h3>
                    <div class="mt-3 grid gap-3 sm:grid-cols-2 xl:grid-cols-1">
                        <div class="relative h-[220px]">
                            <canvas id="typeChart"></canvas>
                            <div id="typeEmpty" class="absolute inset-0 hidden items-center justify-center rounded-xl border border-slate-200 bg-slate-50 p-4 text-center text-slate-500">Aún no hay ventas en este periodo.</div>
                        </div>
                        <div id="typeLegend" class="space-y-2 text-sm"></div>
                    </div>
                </article>

                <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
                    <h3 class="text-2xl font-extrabold text-slate-900">Top 5 ítems más vendidos (Este mes)</h3>
                    <div class="mt-4 space-y-3">
                        @forelse ($topItems as $item)
                            @php
                                $maxTop = collect($topItems)->max('valor_total') ?: 1;
                                $progress = ((float) ($item['valor_total'] ?? 0) / $maxTop) * 100;
                            @endphp
                            <div>
                                <div class="mb-1 flex items-center justify-between gap-3">
                                    <p class="truncate text-sm font-semibold text-slate-800">{{ $item['descripcion'] ?? 'Ítem' }}</p>
                                    <p class="text-xs text-slate-500">{{ number_format((float) ($item['cantidad'] ?? 0), 0, ',', '.') }} {{ $item['unidad'] ?? 'und' }}</p>
                                    <p class="text-sm font-bold text-slate-800">${{ number_format((float) ($item['valor_total'] ?? 0), 0, ',', '.') }}</p>
                                </div>
                                <div class="h-2 overflow-hidden rounded-full bg-slate-200">
                                    <div class="h-full rounded-full bg-emerald-500" style="width: {{ max(5, min(100, $progress)) }}%"></div>
                                </div>
                            </div>
                        @empty
                            <div class="rounded-xl border border-slate-200 bg-slate-50 p-6 text-center text-slate-500">Aún no hay ítems vendidos en este periodo.</div>
                        @endforelse
                    </div>
                </article>
            </section>

            <section class="grid gap-4 xl:grid-cols-2">
                <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
                    <h3 class="text-2xl font-extrabold text-slate-900">Estado de documentos</h3>
                    <div class="mt-4 grid gap-3 sm:grid-cols-3">
                        @foreach (['cotizaciones' => 'Cotizaciones', 'facturas' => 'Facturas', 'productos' => 'Productos'] as $key => $label)
                            @php $block = $estadoDocumentos[$key] ?? ['total' => 0, 'estados' => []]; @endphp
                            <div class="rounded-2xl border border-slate-200 bg-slate-50 p-3">
                                <p class="font-semibold text-slate-800">{{ $label }}</p>
                                <p class="mt-1 text-3xl font-extrabold text-slate-900">{{ (int) ($block['total'] ?? 0) }}</p>
                                <div class="mt-2 space-y-1 text-xs text-slate-500">
                                    @foreach (($block['estados'] ?? []) as $estado => $total)
                                        <p>{{ ucfirst(str_replace('_', ' ', $estado)) }}: {{ (int) $total }}</p>
                                    @endforeach
                                </div>
                            </div>
                        @endforeach
                    </div>
                </article>

                <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
                    <h3 class="text-2xl font-extrabold text-slate-900">Resumen financiero</h3>
                    <div class="mt-4 space-y-2 text-sm">
                        <div class="flex justify-between"><span class="text-slate-600">Ventas (Facturas)</span><span class="font-semibold text-slate-900">${{ number_format((float) ($resumenFinanciero['ventas'] ?? 0), 0, ',', '.') }}</span></div>
                        <div class="flex justify-between"><span class="text-slate-600">Costos de productos vendidos</span><span class="font-semibold text-slate-900">{{ isset($resumenFinanciero['costos_productos']) ? '$'.number_format((float)$resumenFinanciero['costos_productos'],0,',','.') : 'No disponible' }}</span></div>
                        <div class="flex justify-between"><span class="text-slate-600">Gastos operativos</span><span class="font-semibold text-slate-900">{{ isset($resumenFinanciero['gastos_operativos']) ? '$'.number_format((float)$resumenFinanciero['gastos_operativos'],0,',','.') : 'No disponible' }}</span></div>
                        <div class="border-t border-slate-200 pt-2"></div>
                        <div class="flex justify-between text-base"><span class="font-bold text-emerald-700">Utilidad estimada</span><span class="font-extrabold text-emerald-700">{{ isset($resumenFinanciero['utilidad']) ? '$'.number_format((float)$resumenFinanciero['utilidad'],0,',','.') : 'No disponible' }}</span></div>
                    </div>
                    @if (isset($resumenFinanciero['margen_pct']))
                        <p class="mt-3 text-sm text-slate-500">Margen de utilidad: <span class="font-semibold text-slate-800">{{ number_format((float) $resumenFinanciero['margen_pct'], 1, ',', '.') }}%</span></p>
                    @else
                        <p class="mt-3 text-sm text-slate-500">Utilidad estimada no disponible por falta de costos/gastos registrados.</p>
                    @endif
                </article>
            </section>
        </div>
    </div>

    <div id="chartModal" class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-900/70 p-4">
        <div class="w-full max-w-6xl rounded-2xl bg-white p-5 shadow-2xl">
            <div class="mb-3 flex items-center justify-between">
                <h3 id="modalTitle" class="text-2xl font-extrabold text-slate-900">Gráfica</h3>
                <button id="closeModal" class="rounded-lg border border-slate-200 px-3 py-1 text-sm font-semibold text-slate-600">Cerrar</button>
            </div>
            <div class="h-[70vh]"><canvas id="modalChart"></canvas></div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
    <script>
        const dashboard = @json($dashboardData);
        const business = dashboard.business_dashboard || {};
        const graficas = business.graficas || {};

        const cop = (value) => new Intl.NumberFormat('es-CO').format(Number(value || 0));
        const toShortMoney = (value) => {
            const n = Number(value || 0);
            if (n >= 1000000) return `$${(n / 1000000).toFixed(1)}M`;
            if (n >= 1000) return `$${(n / 1000).toFixed(0)}k`;
            return `$${Math.round(n)}`;
        };

        const daily = (graficas.ventas_diarias_periodo || []).map((x) => Number(x.facturado || 0));
        const dailyLabels = (graficas.ventas_diarias_periodo || []).map((x) => x.label || '-');
        const dailyTotal = daily.reduce((a, b) => a + b, 0);
        document.getElementById('dailyTotal').textContent = `$${cop(dailyTotal)}`;

        const yearly = (graficas.ventas_mensuales_anio || []).map((x) => Number(x.total || 0));
        const yearlyLabels = (graficas.ventas_mensuales_anio || []).map((x) => (x.label || x.periodo || '-').split(' ')[0]);
        const yearlyTotal = yearly.reduce((a, b) => a + b, 0);
        document.getElementById('yearlyTotal').textContent = `$${cop(yearlyTotal)}`;

        let dailyChart = null;
        let yearlyChart = null;
        let categoryChart = null;
        let typeChart = null;
        let modalChart = null;

        if (dailyTotal <= 0) {
            document.getElementById('dailyEmpty').classList.remove('hidden');
            document.getElementById('dailyEmpty').classList.add('flex');
        } else {
            dailyChart = new Chart(document.getElementById('dailySalesChart'), {
                type: 'line',
                data: {
                    labels: dailyLabels,
                    datasets: [{
                        data: daily,
                        borderColor: '#0C9A6A',
                        backgroundColor: 'rgba(12,154,106,0.14)',
                        fill: true,
                        tension: 0.35,
                        pointRadius: 3,
                        pointBackgroundColor: '#0C9A6A',
                        borderWidth: 3,
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false },
                        tooltip: {
                            callbacks: {
                                label: (ctx) => `Ventas: $${cop(ctx.parsed.y)}`
                            }
                        }
                    },
                    scales: {
                        x: {
                            ticks: {
                                autoSkip: true,
                                maxTicksLimit: 12,
                                maxRotation: 0,
                                minRotation: 0,
                            },
                            grid: { display: false }
                        },
                        y: {
                            beginAtZero: true,
                            ticks: { callback: (v) => toShortMoney(v) }
                        }
                    }
                }
            });
        }

        if (yearlyTotal <= 0) {
            document.getElementById('yearlyEmpty').classList.remove('hidden');
            document.getElementById('yearlyEmpty').classList.add('flex');
        } else {
            yearlyChart = new Chart(document.getElementById('yearlySalesChart'), {
                type: 'bar',
                data: {
                    labels: yearlyLabels,
                    datasets: [{
                        data: yearly,
                        backgroundColor: '#0C9A6A',
                        borderRadius: 8,
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false },
                        tooltip: {
                            callbacks: {
                                label: (ctx) => `Ventas: $${cop(ctx.parsed.y)}`
                            }
                        }
                    },
                    scales: {
                        x: {
                            ticks: {
                                autoSkip: false,
                                maxRotation: 0,
                                minRotation: 0,
                            }
                        },
                        y: {
                            beginAtZero: true,
                            ticks: { callback: (v) => toShortMoney(v) }
                        }
                    }
                }
            });
        }

        const categoryRaw = graficas.ventas_por_categoria_productos || {};
        const categoryItems = categoryRaw.items || [];
        const categoryValues = categoryItems.map((x) => Number(x.valor || 0));
        const categoryTotal = Number(categoryRaw.total || 0);
        if (categoryTotal <= 0 || !categoryItems.length) {
            document.getElementById('categoryEmpty').classList.remove('hidden');
            document.getElementById('categoryEmpty').classList.add('flex');
        } else {
            categoryChart = new Chart(document.getElementById('categoryChart'), {
                type: 'doughnut',
                data: {
                    labels: categoryItems.map((x) => x.label || x.categoria || 'Sin categoría'),
                    datasets: [{
                        data: categoryValues,
                        backgroundColor: ['#10B981', '#3B82F6', '#8B5CF6', '#F59E0B', '#06B6D4'],
                        borderWidth: 0,
                    }]
                },
                options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } }
            });
        }

        document.getElementById('categoryLegend').innerHTML = categoryItems.map((x) => {
            const label = x.label || x.categoria || 'Sin categoría';
            const value = Number(x.valor || 0);
            const pct = Number(x.porcentaje || 0);
            return `<p class="text-slate-600"><span class="font-semibold text-slate-800">${label}</span>: $${cop(value)} (${pct.toFixed(1)}%)</p>`;
        }).join('') || '<p class="text-slate-500">Sin datos.</p>';

        const typeRaw = graficas.ventas_por_tipo || {};
        const typeItems = typeRaw.items || [];
        const typeValues = typeItems.map((x) => Number(x.valor || 0));
        const typeTotal = Number(typeRaw.total || 0);
        if (typeTotal <= 0 || !typeItems.length) {
            document.getElementById('typeEmpty').classList.remove('hidden');
            document.getElementById('typeEmpty').classList.add('flex');
        } else {
            typeChart = new Chart(document.getElementById('typeChart'), {
                type: 'doughnut',
                data: {
                    labels: typeItems.map((x) => x.label || x.tipo || '-'),
                    datasets: [{
                        data: typeValues,
                        backgroundColor: ['#10B981', '#3B82F6'],
                        borderWidth: 0,
                    }]
                },
                options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } }
            });
        }

        document.getElementById('typeLegend').innerHTML = typeItems.map((x) => {
            const label = x.label || x.tipo || '-';
            const value = Number(x.valor || 0);
            const pct = Number(x.porcentaje || 0);
            return `<p class="text-slate-600"><span class="font-semibold text-slate-800">${label}</span>: $${cop(value)} (${pct.toFixed(1)}%)</p>`;
        }).join('') || '<p class="text-slate-500">Sin datos.</p>';

        const modal = document.getElementById('chartModal');
        const modalTitle = document.getElementById('modalTitle');
        const closeModal = document.getElementById('closeModal');

        const openModalWithChart = (kind) => {
            if (modalChart) {
                modalChart.destroy();
                modalChart = null;
            }
            const ctx = document.getElementById('modalChart');
            if (kind === 'daily') {
                modalTitle.textContent = 'Ventas diarias (Este mes)';
                modalChart = new Chart(ctx, {
                    type: 'line',
                    data: {
                        labels: dailyLabels,
                        datasets: [{ data: daily, borderColor: '#0C9A6A', backgroundColor: 'rgba(12,154,106,0.14)', fill: true, tension: 0.35, pointRadius: 3, borderWidth: 3 }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: { legend: { display: false }, tooltip: { callbacks: { label: (c) => `Ventas: $${cop(c.parsed.y)}` } } },
                        scales: { y: { beginAtZero: true, ticks: { callback: (v) => toShortMoney(v) } } }
                    }
                });
            } else {
                modalTitle.textContent = 'Ventas por mes (Este año)';
                modalChart = new Chart(ctx, {
                    type: 'bar',
                    data: { labels: yearlyLabels, datasets: [{ data: yearly, backgroundColor: '#0C9A6A', borderRadius: 8 }] },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: { legend: { display: false }, tooltip: { callbacks: { label: (c) => `Ventas: $${cop(c.parsed.y)}` } } },
                        scales: { y: { beginAtZero: true, ticks: { callback: (v) => toShortMoney(v) } } }
                    }
                });
            }
            modal.classList.remove('hidden');
            modal.classList.add('flex');
        };

        document.querySelectorAll('[data-expand-chart]').forEach((btn) => {
            btn.addEventListener('click', () => openModalWithChart(btn.getAttribute('data-expand-chart')));
        });

        closeModal.addEventListener('click', () => {
            modal.classList.add('hidden');
            modal.classList.remove('flex');
            if (modalChart) {
                modalChart.destroy();
                modalChart = null;
            }
        });

        modal.addEventListener('click', (event) => {
            if (event.target === modal) closeModal.click();
        });
    </script>
</x-app-layout>
