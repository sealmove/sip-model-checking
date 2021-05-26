mtype = {invite, ack, bye, trying, ringing, ok}

chan toAlice = [0] of {mtype};
chan toBob   = [0] of {mtype};
chan toProxy = [0] of {mtype}; 

proctype alice() {
    toProxy!invite;

S1: do
    :: toAlice?trying
    :: toAlice?ringing
    :: toAlice?ok -> toBob!ack; goto S2
    od;

S2: do
    :: timeout
    :: toBob!bye; goto S3
    od;

S3: do
    :: toAlice?ok; break
    od;
}

proctype proxy() {
    do
    :: toProxy?invite -> toAlice!trying; toBob!invite
    :: toProxy?ok -> toAlice!ok
    :: toProxy?ringing -> toAlice!ringing
    od
}

proctype bob() {
    toBob?invite;

S1: do
    :: toProxy!ringing; toProxy!ok -> goto S2
    od;

S2: do
    :: toBob?ack -> goto S3
    od;

S3: do
    :: toBob?bye -> toAlice!ok; break
    od;
}

init {
    run alice();
    run proxy();
    run bob();
}
