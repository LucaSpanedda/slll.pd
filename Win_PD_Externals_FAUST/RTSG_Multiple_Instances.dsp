// ---------------------------------------------------------------------------------

/*
REAL TIME SYNCHRONOUS GRANULATOR with COUNTER:
100 Milliseconds grains with Envelope window shape control.
ON PARALLEL FIXED TABLES OF 1 SECOND (TAPES)
*/

// import Standard Faust library
// https://github.com/grame-cncm/faustlibraries/
import("stdfaust.lib");

counter = hslider("[0] Grains Rec",1,1,40,1);
ampguiin = hslider("[1] Grains Amp In",1,0,1,0.01);
windowgui = hslider("[4] Grains Window",1,1,200,1);
ampgui = hslider("[2] Grains Amp Out",0.1,0,10,0.1);
freqguiplus = hslider("[5] Grains Freq+",1,1,100,1);
freqguiminus = hslider("[6] Grains Freq/",1,1,100,1);
feedbackgui = hslider("[3] Rec Feedback",0,0,1,0.01);

// GRAIN
grain(numbpar,freq,seed,powwindow,amp) = 
(rwtable(dimension,0.0,indexwrite,_,indexread)*envelope) <: panning
with{
    // COUNTER
    condpar = (counter == numbpar); // if counter match par then 1
    condmaj = (condpar > 0.5);
    condmin = (condpar < 0.5) : mem;
    diracmatch = condmaj*condmin;
    // GATE (FOR REC) - PEAK HOLD
    peakcond(holdTime, x_) = loop ~ _ // hold the dirac impulse for 1000 ms
            with {loop(pFB) = ba.if(pReset, abs(x_), pFB)
            with {pReset = timerCond | peakCond;
            peakCond = abs(x_) >= pFB;
            timerCond = loop ~ _
            with {loop(tFB) = fi.pole(tReset, tReset) >= (holdTime)
            with {tReset = 1 - (peakCond | tFB);
        };};};};
        partrigger = peakcond(ma.SR, diracmatch); // out 1 for 1 second when match

    // NOISE & PHASOR GENERATION
    noise = (((+(seed)~*(1103515245))/2147483647.0)+1)*0.5;  
    noisepan1 = (((+(seed)~*(1443518942))/2147483647.0)+1)*0.5;
    noisepan2 = (((+(seed)~*(1423515748))/2147483647.0)+1)*0.5;
    decimale(step)=((step)-int(step));
    decorrelation = ((((seed)*(1103515245)/2147483647.0)+1)*0.5)*ma.SR; // rand
    fasore = (((freq*10)/ma.SR):(+:decimale)~ _) : _@(decorrelation);
    // IMPULSE GENERATION
    saw = (fasore*-1)+1;
    phasemaj = (saw > 0.5);
    phasemin = (saw < 0.5) : mem;
    diracphase = phasemaj*phasemin;
    // SAH THE NOISE FUNCTION (with the impulse)
    sahrandom = (*(1 - diracphase) + noise * diracphase) ~ _;
    sahrandompan1 = (*(1 - diracphase) + noisepan1 * diracphase) ~ _;
    sahrandompan2 = (*(1 - diracphase) + noisepan2 * diracphase) ~ _;
    sehout = (sahrandom +1)/2;
    sehoutpan1 = (sahrandompan1 +1)/2;
    sehoutpan2 = (sahrandompan2 +1)/2;

    // READER 
    recstart = partrigger; // when match the i (par) instance then record
    record = recstart : int; // record the memory with the int value of 1
    dimension = 192000;
    indexwrite = (+(1) : %(ma.SR : int))~ *(record);
    indexread = ((fasore*(ma.SR*0.1)) + (sehout*(ma.SR*0.9))) : int;

    // ENVELOPE & POW
    envelope = ((sin(fasore*ma.PI)):pow(powwindow)*amp); // reder used for env
    panning = _*(sehoutpan1), _*(sehoutpan2);
	};

// GRANULATOR: PARALLEL PROCESS OF THE GRAIN FUNCTION
parallelgrains = 
             // granulator (with par on grain function)
             // grain(==numbpar,Hz-read,seed-noise,window-shape(pow),amp)
_ <: par( i, 40, grain(i+1,freqguiplus/freqguiminus,219979*(i+1),windowgui,ampgui) );

routingranulator(a,b) = (a+b)*feedbackgui, a, b;
routeout(a,b,c) = b, c;
routegrains = _*ampguiin : (+ : parallelgrains :> routingranulator) ~ _ : routeout;
process = routegrains ;

// ---------------------------------------------------------------------------------