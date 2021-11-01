// FASORE SPLICE

//Importo la libreria
import("stdfaust.lib");

// Graphic User Interface ----------------------------------------
frequency = hslider("frequency",0,0,20000, 0.01);
freqscattering = hslider("freqscattering",0,0,20000, 0.01);
impulsesamps = hslider("samples",0,0,20000, 1);
variableseed = hslider("varseed",0,0,20000, 1);
// ---------------------------------------------------------------

/* Ora che abbiamo parlato molto della generazione di segnali
raccogliamo i dati esposti fino ad ora per generare un segnale
non convenzionale: un Fasore con dei Glitch interni controllati */

// VARIABLE SEED NOISE FUNCTION
// Ad ogni cambiamento del seed corrisponde un nuovo valore casuale
noise(seed) = vnoiseout
with{
// Remove integer values
decimalen(x)= x-int(x);
    vnoiseout  = (+(1457932343)~*(1103515245)) * (1+seed)
        / (2147483647.0) : decimalen;
};

// Remove int
decimale(x) = x-int(x);
// Standard phasor (with remove int)
phasor(f) = (f/ma.SR) : (+ : decimale) ~ _;

// only if phasor < 0.5 = 1 (when phasor end) then impulse
phasorif(f) = phasor(f) < 0.5;
impulse(samples) = (_ <: _, _@(1+samples) :> -) > 0;

// NOISE * IMPULSE : phasor reset = impulse (1 constant) * noise
pulse(f,samples,seed) = (phasorif(f) : impulse(samples)) * noise(seed);

// SCATTERING PHASOR
// regular impulse + 1 on the retroaction generate scatter
splicephasor(fphasor,fscatter,sampsdur,seed) = 
    ( (fphasor/ma.SR) : 
        ( + : _ * 
            (1 + (pulse(fscatter,sampsdur,seed)) ) : decimale
        )~ _ );


// splicephasor(frequency,freqscattering,impulsesamps,variableseed)
process = 
    splicephasor(frequency,freqscattering,impulsesamps,variableseed);
