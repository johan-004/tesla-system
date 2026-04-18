<?php

namespace App\Http\Controllers;

use App\Models\Cotizacion;
use Illuminate\Http\Request;

class CotizacionController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $cotizaciones = Cotizacion::orderBy('fecha', 'desc')->paginate(10);

        return view('cotizaciones.index', compact('cotizaciones'));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        return view('cotizaciones.create');
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
{
    $request->validate([
        'item' => 'required',
        'obra' => 'required',
        'descripcion' => 'required',
        'unidad' => 'required',
        'fecha' => 'required'
    ]);

    Cotizacion::create($request->all());

    return redirect()->route('cotizaciones.index')
        ->with('success', 'Cotización creada correctamente');
}

    /**
     * Display the specified resource.
     */
    public function show($id)
    {
        $cotizacion = \App\Models\Cotizacion::findOrFail($id);

        return view('cotizaciones.show', compact('cotizacion'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }
}