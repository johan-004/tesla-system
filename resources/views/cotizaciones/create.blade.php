<x-app-layout>

<div class="max-w-4xl mx-auto p-6">

<h1 class="text-2xl font-bold mb-6">Nueva Cotización</h1>

<form action="{{ route('cotizaciones.store') }}" method="POST">

@csrf

<div class="grid grid-cols-2 gap-4">

<div>
<label class="block">Item</label>
<input type="text" name="item" class="w-full border p-2 rounded" placeholder="A.1">
</div>

<div>
<label class="block">Unidad</label>
<input type="text" name="unidad" class="w-full border p-2 rounded" placeholder="ML / M2">
</div>

<div class="col-span-2">
<label class="block">Obra / Servicio</label>
<input type="text" name="obra" class="w-full border p-2 rounded">
</div>

<div class="col-span-2">
<label class="block">Descripción</label>
<textarea name="descripcion" class="w-full border p-2 rounded"></textarea>
</div>

<div>
<label class="block">Fecha</label>
<input type="date" name="fecha" class="w-full border p-2 rounded">
</div>

<div>
<label class="block">Factor Zona</label>
<input type="number" step="0.01" name="factor_zona" value="1" class="w-full border p-2 rounded">
</div>

<div>
<label class="block">AIU (%)</label>
<input type="number" step="0.01" name="aiu" class="w-full border p-2 rounded">
</div>

</div>

<div class="flex gap-3 mt-6">

<a href="{{ route('cotizaciones.index') }}"
class="bg-gray-500 text-white px-4 py-2 rounded">
Cancelar
</a>

<button type="submit"
class="bg-blue-600 text-white px-4 py-2 rounded">
Guardar Cotización
</button>

</div>

</form>

</div>

</x-app-layout>