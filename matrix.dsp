// MATRICE (GUI)

//Importo la libreria standard di FAUST
import("stdfaust.lib");

Fader(in)		= checkbox("IN %in");
Mixer(N,out) 	= hgroup("OUT %out", par(in, N, *(Fader(in)) ) :> _ );
Matrix(N,M) 	= vgroup("Matrix %N x %M", par(in, N, _) <: par(out, M, Mixer(N, out)));

process = Matrix(8, 8);