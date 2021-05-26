mtype = {invite, ack, bye, trying, ringing, okInvite, okBye}

chan n2a = [1] of {mtype};
chan a2n = [1] of {mtype};
chan n2p = [1] of {mtype};
chan p2n = [1] of {mtype};
chan n2b = [1] of {mtype};
chan b2n = [1] of {mtype};

proctype alice() {
    a2n!invite;

S1: do
    :: n2a?trying
    :: n2a?ringing
    :: n2a?okInvite -> a2n!ack; goto S2
    od;

S2: do
    :: timeout
    :: a2n!bye; goto S3
    od;

S3: do
    :: n2a?okBye; break
    od;
}

proctype proxy() {
    do
    :: n2p?invite -> p2n!trying; p2n!invite
    :: n2p?okInvite -> p2n!okInvite
    :: n2p?ringing -> p2n!ringing
    od
}

proctype bob() {
    n2b?invite;

S1: do
    :: b2n!ringing; b2n!okInvite -> goto S2
    od;

S2: do
    :: n2b?ack -> goto S3
    od;

S3: do
    :: n2b?bye -> b2n!okBye; break
    od;
}

proctype net() {
    do
    :: a2n?invite -> n2p!invite
    :: a2n?ack -> n2b!ack
    :: a2n?bye -> n2b!bye
    :: b2n?ringing -> n2p!ringing
    :: b2n?okInvite -> n2p!okInvite
    :: b2n?okBye -> n2a!okBye
    :: p2n?invite -> n2b!invite
    :: p2n?ringing -> n2a!ringing
    :: p2n?trying -> n2a!trying
    :: p2n?okInvite -> n2a!okInvite
    od
}

init {
    run net();
    run alice();
    run proxy();
    run bob();
}
