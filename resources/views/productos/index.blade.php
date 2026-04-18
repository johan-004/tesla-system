<x-app-layout>
    @php
        $sortUrl = function (string $campo) use ($buscar, $estado, $orden, $direccion) {
            $nextDirection = $orden === $campo && $direccion === 'asc' ? 'desc' : 'asc';

            return route('web.productos.index', [
                'buscar' => $buscar,
                'estado' => $estado,
                'orden' => $campo,
                'direccion' => $nextDirection,
            ]);
        };

        $sortIndicator = function (string $campo) use ($orden, $direccion) {
            if ($orden !== $campo) {
                return '';
            }

            return $direccion === 'asc' ? '↑' : '↓';
        };
    @endphp

    <style>
        [x-cloak] { display: none !important; }
    </style>

    <div class="min-h-screen bg-slate-100">
        <div
            x-data="productosSearch({
                suggestionsUrl: @js(route('web.productos.sugerencias')),
                initialSearch: @js($buscar),
            })"
            class="mx-auto max-w-6xl px-4 py-8 sm:px-6 lg:px-8"
        >
            <section class="mx-auto max-w-5xl overflow-hidden rounded-[28px] bg-gradient-to-br from-slate-900 via-slate-800 to-emerald-900 shadow-xl shadow-slate-300/60">
                <div class="flex flex-col gap-6 px-6 py-7 text-white sm:px-8 lg:flex-row lg:items-end lg:justify-between">
                    <div class="max-w-2xl">
                        <span class="inline-flex rounded-full border border-white/15 bg-white/10 px-3 py-1 text-xs font-semibold uppercase tracking-[0.2em] text-slate-200">
                            Módulo web
                        </span>
                        <h1 class="mt-4 text-3xl font-semibold tracking-tight sm:text-4xl">Productos</h1>
                        <p class="mt-2 text-sm leading-6 text-slate-200 sm:text-base">
                            Administra el catálogo de forma clara, rápida y ordenada desde escritorio.
                        </p>
                    </div>

                    <a href="{{ route('web.productos.create') }}"
                       class="inline-flex items-center justify-center rounded-xl bg-emerald-400 px-5 py-3 text-sm font-semibold text-slate-950 shadow-lg shadow-emerald-950/20 transition hover:bg-emerald-300">
                        Nuevo producto
                    </a>
                </div>
            </section>

            <div class="mx-auto mt-5 max-w-5xl space-y-3">
                @if(session('success'))
                    <div class="rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700 shadow-sm">
                        {{ session('success') }}
                    </div>
                @endif

                @if(session('error'))
                    <div class="rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700 shadow-sm">
                        {{ session('error') }}
                    </div>
                @endif
            </div>

            <section class="mx-auto mt-6 max-w-5xl rounded-[28px] border border-slate-200 bg-white p-5 shadow-lg shadow-slate-200/70 sm:p-6">
                <div class="flex flex-col gap-1">
                    <h2 class="text-lg font-semibold text-slate-900">Buscar y filtrar</h2>
                    <p class="text-sm text-slate-500">Encuentra productos por nombre o código y organiza el listado.</p>
                </div>

                <form method="GET" action="{{ route('web.productos.index') }}" class="mt-5 space-y-5" x-ref="searchForm">
                    <div class="max-w-2xl">
                        <label for="buscar" class="mb-2 block text-sm font-medium text-slate-700">Buscar</label>
                        <div class="relative" @click.outside="closeSuggestions()">
                            <input
                                id="buscar"
                                type="text"
                                name="buscar"
                                x-model="term"
                                @input.debounce.250ms="handleInput()"
                                @focus="handleFocus()"
                                @keydown.escape="closeSuggestions()"
                                placeholder="Ejemplo: MAT-010 o cable"
                                autocomplete="off"
                                class="w-full rounded-2xl border-slate-300 bg-slate-50 px-4 py-3 pr-11 text-sm text-slate-700 shadow-sm transition focus:border-emerald-500 focus:bg-white focus:ring-emerald-500">

                            <button
                                x-cloak
                                x-show="term.length > 0"
                                type="button"
                                @click="clearSearch()"
                                class="absolute inset-y-0 right-3 inline-flex items-center text-slate-400 transition hover:text-slate-600"
                            >
                                <span class="text-lg leading-none">×</span>
                            </button>

                            <div
                                x-cloak
                                x-show="dropdownVisible"
                                class="absolute left-0 right-0 top-full z-20 mt-2 overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl shadow-slate-200/80"
                            >
                                <div x-show="loading" class="px-4 py-3 text-sm text-slate-500">
                                    Buscando productos...
                                </div>

                                <template x-if="!loading && suggestions.length > 0">
                                    <ul class="max-h-80 overflow-y-auto py-2">
                                        <template x-for="producto in suggestions" :key="producto.id">
                                            <li>
                                                <button
                                                    type="button"
                                                    @mousedown.prevent="selectSuggestion(producto)"
                                                    class="flex w-full items-start justify-between gap-3 px-4 py-3 text-left transition hover:bg-slate-50"
                                                >
                                                    <div>
                                                        <div class="flex items-center gap-2">
                                                            <span class="inline-flex rounded-xl bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700" x-text="producto.codigo"></span>
                                                            <span class="text-sm font-semibold text-slate-900" x-text="producto.nombre"></span>
                                                        </div>
                                                        <div class="mt-1 text-xs text-slate-500">
                                                            <span x-text="'Stock: ' + producto.stock + ' ' + producto.unidad_medida"></span>
                                                        </div>
                                                    </div>

                                                    <div class="text-right">
                                                        <div class="text-sm font-semibold text-slate-900" x-text="'$' + producto.precio_venta"></div>
                                                        <span
                                                            class="mt-1 inline-flex rounded-full px-2.5 py-1 text-[11px] font-semibold"
                                                            :class="producto.activo ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-200 text-slate-700'"
                                                            x-text="producto.activo ? 'Activo' : 'Inactivo'"
                                                        ></span>
                                                    </div>
                                                </button>
                                            </li>
                                        </template>
                                    </ul>
                                </template>

                                <div x-show="!loading && noResults" class="px-4 py-3 text-sm text-slate-500">
                                    No se encontraron productos.
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="flex flex-wrap gap-2">
                        <button type="submit" name="estado" value="todos"
                            class="rounded-full px-4 py-2 text-sm font-medium transition {{ $estado === 'todos' ? 'bg-slate-900 text-white shadow-sm' : 'bg-slate-100 text-slate-600 hover:bg-slate-200' }}">
                            Todos
                        </button>
                        <button type="submit" name="estado" value="activos"
                            class="rounded-full px-4 py-2 text-sm font-medium transition {{ $estado === 'activos' ? 'bg-emerald-600 text-white shadow-sm' : 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100' }}">
                            Activos
                        </button>
                        <button type="submit" name="estado" value="inactivos"
                            class="rounded-full px-4 py-2 text-sm font-medium transition {{ $estado === 'inactivos' ? 'bg-rose-600 text-white shadow-sm' : 'bg-rose-50 text-rose-700 hover:bg-rose-100' }}">
                            Inactivos
                        </button>
                    </div>

                    <div class="flex flex-col gap-4 xl:flex-row xl:flex-wrap xl:items-end">
                        <div>
                            <label for="orden" class="mb-2 block text-sm font-medium text-slate-700">Ordenar por</label>
                            <select id="orden" name="orden" class="w-full rounded-2xl border-slate-300 bg-slate-50 px-4 py-3 text-sm text-slate-700 shadow-sm transition focus:border-emerald-500 focus:bg-white focus:ring-emerald-500 xl:w-52">
                                <option value="codigo" @selected($orden === 'codigo')>Código</option>
                                <option value="nombre" @selected($orden === 'nombre')>Nombre</option>
                                <option value="stock" @selected($orden === 'stock')>Stock</option>
                                <option value="precio_venta" @selected($orden === 'precio_venta')>Precio</option>
                                <option value="activo" @selected($orden === 'activo')>Estado</option>
                            </select>
                        </div>

                        <div>
                            <label for="direccion" class="mb-2 block text-sm font-medium text-slate-700">Dirección</label>
                            <select id="direccion" name="direccion" class="w-full rounded-2xl border-slate-300 bg-slate-50 px-4 py-3 text-sm text-slate-700 shadow-sm transition focus:border-emerald-500 focus:bg-white focus:ring-emerald-500 xl:w-52">
                                <option value="asc" @selected($direccion === 'asc')>Ascendente</option>
                                <option value="desc" @selected($direccion === 'desc')>Descendente</option>
                            </select>
                        </div>

                        <div class="flex items-end gap-3">
                            <button type="submit" class="inline-flex items-center justify-center rounded-xl bg-slate-900 px-5 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800">
                                Aplicar
                            </button>
                            <a href="{{ route('web.productos.index') }}" class="inline-flex items-center justify-center rounded-xl border border-slate-300 bg-white px-5 py-3 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50">
                                Limpiar
                            </a>
                        </div>
                    </div>
                </form>
            </section>

            <section class="mx-auto mt-6 max-w-5xl overflow-hidden rounded-[28px] border border-slate-200 bg-white shadow-lg shadow-slate-200/70">
                <div class="flex flex-col gap-2 border-b border-slate-200 bg-slate-50/80 px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
                    <div>
                        <p class="text-sm font-medium text-slate-700">{{ $productos->total() }} productos</p>
                        <p class="text-sm text-slate-500">Página {{ $productos->currentPage() }} de {{ $productos->lastPage() }}</p>
                    </div>
                    <div class="text-sm text-slate-500">
                        Orden actual:
                        <span class="font-semibold text-slate-700">{{ ucfirst(str_replace('_', ' ', $orden)) }}</span>
                    </div>
                </div>

                <div class="overflow-x-auto">
                    <table class="min-w-full">
                        <thead class="bg-slate-50 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                            <tr>
                                <th class="px-5 py-4">
                                    <a href="{{ $sortUrl('codigo') }}" class="inline-flex items-center gap-1 transition hover:text-slate-900">
                                        Código
                                        <span>{{ $sortIndicator('codigo') }}</span>
                                    </a>
                                </th>
                                <th class="px-5 py-4">
                                    <a href="{{ $sortUrl('nombre') }}" class="inline-flex items-center gap-1 transition hover:text-slate-900">
                                        Nombre
                                        <span>{{ $sortIndicator('nombre') }}</span>
                                    </a>
                                </th>
                                <th class="px-5 py-4">Unidad</th>
                                <th class="px-5 py-4">
                                    <a href="{{ $sortUrl('precio_venta') }}" class="inline-flex items-center gap-1 transition hover:text-slate-900">
                                        Precio
                                        <span>{{ $sortIndicator('precio_venta') }}</span>
                                    </a>
                                </th>
                                <th class="px-5 py-4">
                                    <a href="{{ $sortUrl('stock') }}" class="inline-flex items-center gap-1 transition hover:text-slate-900">
                                        Stock
                                        <span>{{ $sortIndicator('stock') }}</span>
                                    </a>
                                </th>
                                <th class="px-5 py-4">
                                    <a href="{{ $sortUrl('activo') }}" class="inline-flex items-center gap-1 transition hover:text-slate-900">
                                        Estado
                                        <span>{{ $sortIndicator('activo') }}</span>
                                    </a>
                                </th>
                                <th class="px-5 py-4 text-right">Acciones</th>
                            </tr>
                        </thead>

                        <tbody class="divide-y divide-slate-100 text-sm text-slate-700">
                            @forelse($productos as $producto)
                                <tr class="transition hover:bg-slate-50/80">
                                    <td class="whitespace-nowrap px-5 py-4">
                                        <span class="inline-flex rounded-xl bg-slate-100 px-3 py-1.5 font-semibold text-slate-700">
                                            {{ $producto->codigo }}
                                        </span>
                                    </td>
                                    <td class="px-5 py-4">
                                        <div class="font-semibold text-slate-900">{{ $producto->nombre }}</div>
                                    </td>
                                    <td class="whitespace-nowrap px-5 py-4 text-slate-600">{{ $producto->unidad_medida }}</td>
                                    <td class="whitespace-nowrap px-5 py-4 font-semibold text-slate-900">${{ number_format((float) $producto->precio_venta, 2) }}</td>
                                    <td class="whitespace-nowrap px-5 py-4">
                                        @if($producto->stock <= 5)
                                            <span class="inline-flex rounded-full bg-amber-100 px-3 py-1 text-xs font-semibold text-amber-800">
                                                {{ $producto->stock }} bajo
                                            </span>
                                        @else
                                            <span class="font-medium text-slate-700">{{ $producto->stock }}</span>
                                        @endif
                                    </td>
                                    <td class="whitespace-nowrap px-5 py-4">
                                        <span class="inline-flex rounded-full px-3 py-1 text-xs font-semibold {{ $producto->activo ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-200 text-slate-700' }}">
                                            {{ $producto->activo ? 'Activo' : 'Inactivo' }}
                                        </span>
                                    </td>
                                    <td class="px-5 py-4">
                                        <div class="flex flex-wrap justify-end gap-2">
                                            <a href="{{ route('web.productos.edit', $producto) }}"
                                               class="inline-flex items-center rounded-xl border border-slate-300 bg-white px-3 py-2 text-xs font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50">
                                                Editar
                                            </a>

                                            <form action="{{ route('web.productos.toggle-activo', $producto) }}" method="POST">
                                                @csrf
                                                @method('PATCH')
                                                <button
                                                    type="submit"
                                                    onclick="return confirm('¿Seguro que deseas cambiar el estado de este producto?')"
                                                    class="inline-flex items-center rounded-xl px-3 py-2 text-xs font-semibold text-white shadow-sm transition {{ $producto->activo ? 'bg-rose-600 hover:bg-rose-500' : 'bg-emerald-600 hover:bg-emerald-500' }}">
                                                    {{ $producto->activo ? 'Inactivar' : 'Activar' }}
                                                </button>
                                            </form>
                                        </div>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="7" class="px-5 py-14 text-center text-sm text-slate-500">
                                        No hay productos para mostrar.
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>

                @if($productos->hasPages())
                    <div class="flex justify-center border-t border-slate-200 bg-slate-50/70 px-5 py-4">
                        <div class="flex flex-wrap items-center justify-center gap-2">
                            @if($productos->onFirstPage())
                                <span class="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm text-slate-400">Anterior</span>
                            @else
                                <a href="{{ $productos->previousPageUrl() }}" class="rounded-xl border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">
                                    Anterior
                                </a>
                            @endif

                            @foreach($productos->getUrlRange(max(1, $productos->currentPage() - 1), min($productos->lastPage(), $productos->currentPage() + 1)) as $page => $url)
                                @if($page === $productos->currentPage())
                                    <span class="inline-flex h-10 min-w-10 items-center justify-center rounded-xl bg-slate-900 px-3 text-sm font-semibold text-white shadow-sm">
                                        {{ $page }}
                                    </span>
                                @else
                                    <a href="{{ $url }}" class="inline-flex h-10 min-w-10 items-center justify-center rounded-xl border border-slate-300 bg-white px-3 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">
                                        {{ $page }}
                                    </a>
                                @endif
                            @endforeach

                            @if($productos->hasMorePages())
                                <a href="{{ $productos->nextPageUrl() }}" class="rounded-xl bg-slate-900 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800">
                                    Siguiente
                                </a>
                            @else
                                <span class="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm text-slate-400">Siguiente</span>
                            @endif
                        </div>
                    </div>
                @endif
            </section>
        </div>
    </div>

    <script>
        document.addEventListener('alpine:init', () => {
            Alpine.data('productosSearch', ({ suggestionsUrl, initialSearch }) => ({
                term: initialSearch ?? '',
                suggestions: [],
                loading: false,
                dropdownVisible: false,
                noResults: false,
                requestId: 0,

                handleInput() {
                    const value = this.term.trim();

                    if (!value) {
                        this.clearSuggestions();
                        return;
                    }

                    this.fetchSuggestions(value);
                },

                handleFocus() {
                    if (this.term.trim()) {
                        this.fetchSuggestions(this.term.trim());
                    }
                },

                clearSearch() {
                    this.term = '';
                    this.clearSuggestions();
                    this.$refs.searchForm.submit();
                },

                clearSuggestions() {
                    this.suggestions = [];
                    this.loading = false;
                    this.dropdownVisible = false;
                    this.noResults = false;
                },

                closeSuggestions() {
                    this.dropdownVisible = false;
                },

                async fetchSuggestions(value) {
                    const currentRequest = ++this.requestId;
                    this.loading = true;
                    this.dropdownVisible = true;
                    this.noResults = false;

                    try {
                        const url = new URL(suggestionsUrl, window.location.origin);
                        url.searchParams.set('buscar', value);

                        const response = await fetch(url.toString(), {
                            headers: {
                                'Accept': 'application/json',
                                'X-Requested-With': 'XMLHttpRequest',
                            },
                        });

                        const payload = await response.json();

                        if (currentRequest !== this.requestId) {
                            return;
                        }

                        this.suggestions = Array.isArray(payload.data) ? payload.data : [];
                        this.noResults = this.suggestions.length === 0;
                        this.dropdownVisible = true;
                    } catch (_) {
                        if (currentRequest !== this.requestId) {
                            return;
                        }

                        this.suggestions = [];
                        this.noResults = true;
                        this.dropdownVisible = true;
                    } finally {
                        if (currentRequest === this.requestId) {
                            this.loading = false;
                        }
                    }
                },

                selectSuggestion(producto) {
                    this.term = producto.codigo;
                    this.clearSuggestions();
                    this.$refs.searchForm.submit();
                },
            }));
        });
    </script>
</x-app-layout>
