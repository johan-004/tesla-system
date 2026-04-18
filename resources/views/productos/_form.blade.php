@php
    $isEditing = isset($producto);
    $submitLabel = $isEditing ? 'Guardar cambios' : 'Guardar producto';
@endphp

@if ($errors->any())
    <div class="mb-5 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700 shadow-sm">
        @foreach ($errors->all() as $error)
            <p>{{ $error }}</p>
        @endforeach
    </div>
@endif

@if($isEditing)
    <input type="hidden" name="activo" value="0">
@endif

<div class="grid gap-5 sm:grid-cols-2">
    <div>
        <label for="codigo" class="mb-2 block text-sm font-medium text-slate-700">Código</label>
        <input
            id="codigo"
            type="text"
            name="codigo"
            value="{{ old('codigo', $producto->codigo ?? '') }}"
            class="w-full rounded-2xl border-slate-300 bg-slate-50 px-4 py-3 text-sm text-slate-700 shadow-sm transition focus:border-emerald-500 focus:bg-white focus:ring-emerald-500 @error('codigo') border-rose-300 @enderror"
            placeholder="Ejemplo: MAT-010"
            required>
        @error('codigo')
            <p class="mt-2 text-sm text-rose-600">{{ $message }}</p>
        @enderror
    </div>

    <div>
        <label for="unidad_medida" class="mb-2 block text-sm font-medium text-slate-700">Unidad de medida</label>
        <input
            id="unidad_medida"
            type="text"
            name="unidad_medida"
            value="{{ old('unidad_medida', $producto->unidad_medida ?? 'unidad') }}"
            class="w-full rounded-2xl border-slate-300 bg-slate-50 px-4 py-3 text-sm text-slate-700 shadow-sm transition focus:border-emerald-500 focus:bg-white focus:ring-emerald-500 @error('unidad_medida') border-rose-300 @enderror"
            placeholder="unidad"
            required>
        @error('unidad_medida')
            <p class="mt-2 text-sm text-rose-600">{{ $message }}</p>
        @enderror
    </div>

    <div class="sm:col-span-2">
        <label for="nombre" class="mb-2 block text-sm font-medium text-slate-700">Nombre</label>
        <input
            id="nombre"
            type="text"
            name="nombre"
            value="{{ old('nombre', $producto->nombre ?? '') }}"
            class="w-full rounded-2xl border-slate-300 bg-slate-50 px-4 py-3 text-sm text-slate-700 shadow-sm transition focus:border-emerald-500 focus:bg-white focus:ring-emerald-500 @error('nombre') border-rose-300 @enderror"
            placeholder="Nombre del producto"
            required>
        @error('nombre')
            <p class="mt-2 text-sm text-rose-600">{{ $message }}</p>
        @enderror
    </div>

    <div>
        <label for="precio_venta" class="mb-2 block text-sm font-medium text-slate-700">Precio de venta</label>
        <input
            id="precio_venta"
            type="number"
            step="0.01"
            min="0"
            name="precio_venta"
            value="{{ old('precio_venta', $producto->precio_venta ?? '') }}"
            class="w-full rounded-2xl border-slate-300 bg-slate-50 px-4 py-3 text-sm text-slate-700 shadow-sm transition focus:border-emerald-500 focus:bg-white focus:ring-emerald-500 @error('precio_venta') border-rose-300 @enderror"
            required>
        @error('precio_venta')
            <p class="mt-2 text-sm text-rose-600">{{ $message }}</p>
        @enderror
    </div>

    <div>
        <label for="stock" class="mb-2 block text-sm font-medium text-slate-700">Stock</label>
        <input
            id="stock"
            type="number"
            min="0"
            name="stock"
            value="{{ old('stock', $producto->stock ?? '') }}"
            class="w-full rounded-2xl border-slate-300 bg-slate-50 px-4 py-3 text-sm text-slate-700 shadow-sm transition focus:border-emerald-500 focus:bg-white focus:ring-emerald-500 @error('stock') border-rose-300 @enderror"
            required>
        @error('stock')
            <p class="mt-2 text-sm text-rose-600">{{ $message }}</p>
        @enderror
    </div>

    <div class="sm:col-span-2">
        <label class="flex items-center gap-3 rounded-2xl border border-slate-200 bg-slate-50 px-4 py-4">
            <input
                type="checkbox"
                name="activo"
                value="1"
                @checked(old('activo', $producto->activo ?? true))
                class="rounded border-slate-300 text-emerald-600 shadow-sm focus:ring-emerald-500">
            <span class="text-sm font-medium text-slate-700">Producto activo</span>
        </label>
    </div>

    <input type="hidden" name="precio_compra" value="{{ old('precio_compra', $producto->precio_compra ?? 0) }}">
    <input type="hidden" name="descripcion" value="{{ old('descripcion', $producto->descripcion ?? '') }}">
</div>

<div class="mt-8 flex flex-col-reverse gap-3 border-t border-slate-200 pt-6 sm:flex-row sm:justify-between">
    <a href="{{ route('web.productos.index') }}"
       class="inline-flex items-center justify-center rounded-xl border border-slate-300 bg-white px-5 py-3 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50">
        Cancelar
    </a>

    <button type="submit"
        class="inline-flex items-center justify-center rounded-xl bg-emerald-600 px-5 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-emerald-500">
        {{ $submitLabel }}
    </button>
</div>
