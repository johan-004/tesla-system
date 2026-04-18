<x-app-layout>
    <div class="min-h-screen bg-slate-100">
        <div class="mx-auto max-w-3xl px-4 py-8 sm:px-6 lg:px-8">
            <section class="mx-auto max-w-2xl rounded-[28px] bg-gradient-to-br from-slate-900 via-slate-800 to-emerald-900 px-6 py-7 text-white shadow-xl shadow-slate-300/60">
                <a href="{{ route('web.productos.index') }}" class="text-sm font-medium text-slate-200 transition hover:text-white">
                    ← Volver a productos
                </a>
                <h1 class="mt-4 text-3xl font-semibold tracking-tight">Nuevo producto</h1>
                <p class="mt-2 text-sm text-slate-200">
                    Registra un producto nuevo en el catálogo principal.
                </p>
            </section>

            <section class="mx-auto mt-6 max-w-2xl rounded-[28px] border border-slate-200 bg-white p-6 shadow-lg shadow-slate-200/70 sm:p-7">
                <form action="{{ route('web.productos.store') }}" method="POST">
                    @csrf
                    @include('productos._form')
                </form>
            </section>
        </div>
    </div>
</x-app-layout>
