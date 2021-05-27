mtype = {invite, ack, bye, trying, ringing, okInvite, okBye}

#define QSZ 1
#define ALICE 0
#define PROXY 1
#define BOB 2

chan sip2tcp[3] = [QSZ] of {mtype};
chan tcp2sip[3] = [QSZ] of {mtype};
chan tcp2net[3] = [QSZ] of {mtype};
chan net2tcp[3] = [QSZ] of {mtype};

proctype alice() {
    sip2tcp[ALICE]!invite;

S1: do
    :: tcp2sip[ALICE]?trying
    :: tcp2sip[ALICE]?ringing
    :: tcp2sip[ALICE]?okInvite -> sip2tcp[ALICE]!ack; goto S2
    od;

S2: do
    :: timeout
    :: sip2tcp[ALICE]!bye; goto S3
    od;

S3: do
    :: tcp2sip[ALICE]?okBye; break
    od;
}

proctype proxy() {
    do
    :: tcp2sip[PROXY]?invite -> sip2tcp[PROXY]!trying; sip2tcp[PROXY]!invite
    :: tcp2sip[PROXY]?okInvite -> sip2tcp[PROXY]!okInvite
    :: tcp2sip[PROXY]?ringing -> sip2tcp[PROXY]!ringing
    od
}

proctype bob() {
    tcp2sip[BOB]?invite;

S1: do
    :: sip2tcp[BOB]!ringing; sip2tcp[BOB]!okInvite -> goto S2
    od;

S2: do
    :: tcp2sip[BOB]?ack -> goto S3
    od;

S3: do
    :: tcp2sip[BOB]?bye -> sip2tcp[BOB]!okBye; break
    od;
}

proctype tcp(byte id) {
    byte var;
    do
    :: sip2tcp[id]?var -> tcp2net[id]!var
    :: net2tcp[id]?var -> tcp2sip[id]!var
    od
}

proctype net() {
    do
    :: tcp2net[ALICE]?invite -> net2tcp[PROXY]!invite
    :: tcp2net[ALICE]?ack -> net2tcp[BOB]!ack
    :: tcp2net[ALICE]?bye -> net2tcp[BOB]!bye
    :: tcp2net[BOB]?ringing -> net2tcp[PROXY]!ringing
    :: tcp2net[BOB]?okInvite -> net2tcp[PROXY]!okInvite
    :: tcp2net[BOB]?okBye -> net2tcp[ALICE]!okBye
    :: tcp2net[PROXY]?invite -> net2tcp[BOB]!invite
    :: tcp2net[PROXY]?ringing -> net2tcp[ALICE]!ringing
    :: tcp2net[PROXY]?trying -> net2tcp[ALICE]!trying
    :: tcp2net[PROXY]?okInvite -> net2tcp[ALICE]!okInvite
    od
}

init {
    run net();
    run tcp(ALICE);
    run tcp(PROXY);
    run tcp(BOB);
    run alice();
    run proxy();
    run bob();
}
