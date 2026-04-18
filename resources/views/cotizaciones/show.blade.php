@extends('layouts.app')

@section('content')

<style>

.apu-header{
text-align:center;
font-size:22px;
font-weight:bold;
margin-bottom:20px;
}

.apu-table{
width:100%;
border-collapse:collapse;
margin-bottom:20px;
}

.apu-table th,
.apu-table td{
border:1px solid black;
padding:6px;
font-size:14px;
}

.section-title{
background:#e5e5e5;
font-weight:bold;
padding:6px;
border:1px solid black;
margin-top:20px;
}

</style>

<div class="container">

<div class="apu-header">
ANÁLISIS DE PRECIOS UNITARIOS
</div>

<table class="apu-table">

<tr>
<th>OBRA</th>
<td>{{ $cotizacion->obra }}</td>

<th>ITEM</th>
<td>{{ $cotizacion->item }}</td>
</tr>

<tr>
<th>DESCRIPCIÓN</th>
<td>{{ $cotizacion->descripcion }}</td>

<th>UNIDAD</th>
<td>{{ $cotizacion->unidad }}</td>
</tr>

<tr>
<th>FECHA</th>
<td>{{ $cotizacion->fecha }}</td>

<th>FACTOR ZONA</th>
<td>{{ $cotizacion->factor_zona }}</td>
</tr>

<tr>
<th>AIU</th>
<td colspan="3">{{ $cotizacion->aiu }} %</td>
</tr>

</table>

<div class="section-title">
EQUIPO
</div>

<table class="apu-table">

<tr>
<th>Descripción</th>
<th>Unidad</th>
<th>Cantidad</th>
<th>Precio Unit.</th>
<th>Vr. TOTAL</th>
</tr>

@forelse($cotizacion->equipos ?? [] as $equipo)

<tr>
<td>{{ $equipo->descripcion }}</td>
<td>{{ $equipo->unidad }}</td>
<td>{{ $equipo->cantidad }}</td>
<td>{{ $equipo->valor_unitario }}</td>
<td>{{ $equipo->total }}</td>
</tr>

@empty

<tr>
<td colspan="5" style="text-align:center">No hay equipos registrados</td>
</tr>

@endforelse

</table>


<div class="section-title">
TRANSPORTE
</div>

<table class="apu-table">

<tr>
<th>Descripción</th>
<th>Unidad</th>
<th>Cantidad</th>
<th>Tarifa</th>
<th>Vr. TOTAL</th>
</tr>

@forelse($cotizacion->transportes ?? [] as $transporte)

<tr>
<td>{{ $transporte->descripcion }}</td>
<td>{{ $transporte->unidad }}</td>
<td>{{ $transporte->cantidad }}</td>
<td>{{ $transporte->valor_unitario }}</td>
<td>{{ $transporte->total }}</td>
</tr>

@empty

<tr>
<td colspan="5" style="text-align:center">No hay transportes registrados</td>
</tr>

@endforelse

</table>


<div class="section-title">
MANO DE OBRA
</div>

<table class="apu-table">

<tr>
<th>Descripción</th>
<th>Unidad</th>
<th>Cantidad</th>
<th>Valor unitario</th>
<th>Vr. TOTAL</th>
</tr>

@forelse($cotizacion->manoObras ?? [] as $mano)

<tr>
<td>{{ $mano->descripcion }}</td>
<td>{{ $mano->unidad }}</td>
<td>{{ $mano->cantidad }}</td>
<td>{{ $mano->valor_unitario }}</td>
<td>{{ $mano->total }}</td>
</tr>

@empty

<tr>
<td colspan="5" style="text-align:center">No hay mano de obra registrada</td>
</tr>

@endforelse

</table>

<br>

<a href="{{ route('cotizaciones.index') }}" class="btn btn-secondary">
Volver
</a>

</div>

@endsection