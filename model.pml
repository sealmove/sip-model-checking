mtype = {invite, ack, bye, cancel, trying, ringing, ok}

#define QSZ 1
#define ALICE 0
#define PROXY 1
#define BOB 2

chan sip2tcp[3] = [QSZ] of {mtype, byte};
chan tcp2sip[3] = [QSZ] of {mtype, byte};
chan tcp2net[3] = [QSZ] of {mtype, byte};
chan net2tcp[3] = [QSZ] of {mtype, byte};

proctype alice() {
    sip2tcp[ALICE]!invite;

S1: do
    :: tcp2sip[ALICE]?trying
    :: tcp2sip[ALICE]?ringing
    :: tcp2sip[ALICE]?ok, invite -> sip2tcp[ALICE]!ack; goto S2
    :: tcp2sip[ALICE]?cancel -> goto S4
    od;

S2: do
    :: sip2tcp[ALICE]!bye; goto S3
    od;

S3: do
    :: tcp2sip[ALICE]?ok, bye; goto S4
    od;

S4: assert(true)
}

proctype proxy() {
    do
    :: tcp2sip[PROXY]?invite -> sip2tcp[PROXY]!trying; sip2tcp[PROXY]!invite
    :: tcp2sip[PROXY]?ok, invite -> sip2tcp[PROXY]!ok, invite
    :: tcp2sip[PROXY]?ringing -> sip2tcp[PROXY]!ringing
    :: tcp2sip[PROXY]?cancel -> sip2tcp[PROXY]!cancel
    od
}

proctype bob() {
    tcp2sip[BOB]?invite;

S1: do
    :: sip2tcp[BOB]!ringing; sip2tcp[BOB]!ok, invite -> goto S2
    :: sip2tcp[BOB]!cancel -> goto S4
    od;

S2: do
    :: tcp2sip[BOB]?ack -> goto S3
    od;

S3: do
    :: tcp2sip[BOB]?bye -> sip2tcp[BOB]!ok, bye; goto S4
    od;

S4: assert(true)
}

proctype tcp(byte id) {
    byte x, y;
    do
    :: sip2tcp[id]?x, y -> tcp2net[id]!x, y
    :: net2tcp[id]?x, y -> tcp2sip[id]!x, y
    od
}

proctype net() {
    do
    :: tcp2net[ALICE]?invite -> net2tcp[PROXY]!invite
    :: tcp2net[ALICE]?ack -> net2tcp[BOB]!ack
    :: tcp2net[ALICE]?bye -> net2tcp[BOB]!bye
    :: tcp2net[BOB]?ringing -> net2tcp[PROXY]!ringing
    :: tcp2net[BOB]?ok, invite -> net2tcp[PROXY]!ok, invite
    :: tcp2net[BOB]?ok, bye -> net2tcp[ALICE]!ok, bye
    :: tcp2net[BOB]?cancel -> net2tcp[PROXY]!cancel
    :: tcp2net[PROXY]?invite -> net2tcp[BOB]!invite
    :: tcp2net[PROXY]?ringing -> net2tcp[ALICE]!ringing
    :: tcp2net[PROXY]?trying -> net2tcp[ALICE]!trying
    :: tcp2net[PROXY]?ok, invite -> net2tcp[ALICE]!ok, invite
    :: tcp2net[PROXY]?cancel -> net2tcp[ALICE]!cancel
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
