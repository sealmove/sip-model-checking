mtype = {msg, invite, ack, bye, cancel, trying, ringing, ok, error}

#define QSZ 1
#define ALICE 0
#define PROXY 1
#define BOB 2

chan sip2tcp[3] = [QSZ] of {mtype, mtype};
chan tcp2sip[3] = [QSZ] of {mtype, mtype};
chan tcp2net[3] = [QSZ] of {mtype, mtype};
chan net2tcp[3] = [QSZ] of {mtype, mtype};

proctype alice() {
    sip2tcp[ALICE]!invite;

S1: do
    :: tcp2sip[ALICE]?trying
    :: tcp2sip[ALICE]?ringing
    :: tcp2sip[ALICE]?ok, invite -> sip2tcp[ALICE]!ack; goto S2
    :: tcp2sip[ALICE]?cancel -> goto S5
    :: tcp2sip[ALICE]?error -> goto S5
    od;

S2: do
    :: sip2tcp[ALICE]!msg -> goto S3;
    :: tcp2sip[ALICE]?msg;
    :: sip2tcp[ALICE]!bye; goto S4
    :: tcp2sip[ALICE]?bye -> sip2tcp[ALICE]!ok, bye; goto S5
    od;

S3: do
    :: tcp2sip[ALICE]?msg -> goto S2;
    od;

S4: do
    :: tcp2sip[ALICE]?ok, bye -> goto S5
    od;

S5: assert(true)
}

proctype proxy() {
    do
    :: tcp2sip[PROXY]?invite ->
       sip2tcp[PROXY]!trying;
       if
       :: sip2tcp[PROXY]!invite
       :: sip2tcp[PROXY]!error
       fi
    :: tcp2sip[PROXY]?ok, invite -> sip2tcp[PROXY]!ok, invite
    :: tcp2sip[PROXY]?ringing -> sip2tcp[PROXY]!ringing
    :: tcp2sip[PROXY]?cancel -> sip2tcp[PROXY]!cancel
    od
}

proctype bob() {
    tcp2sip[BOB]?invite;

S1: do
    :: sip2tcp[BOB]!ringing;
       if
       :: sip2tcp[BOB]!ok, invite -> goto S2
       :: sip2tcp[BOB]!cancel -> goto S6
       fi
    od;

S2: do
    :: tcp2sip[BOB]?ack -> goto S3
    od;

S3: do
    :: sip2tcp[BOB]!msg -> goto S4;
    :: tcp2sip[BOB]?msg;
    :: sip2tcp[BOB]!bye; goto S5
    :: tcp2sip[BOB]?bye -> sip2tcp[BOB]!ok, bye; goto S6
    od;

S4: do
    :: tcp2sip[ALICE]?msg -> goto S3;
    od;

S5: do
    :: tcp2sip[BOB]?ok, bye; goto S6
    od;

S6: assert(true)
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
    :: tcp2net[ALICE]?msg -> net2tcp[BOB]!msg
    :: tcp2net[ALICE]?invite -> net2tcp[PROXY]!invite
    :: tcp2net[ALICE]?ack -> net2tcp[BOB]!ack
    :: tcp2net[ALICE]?bye -> net2tcp[BOB]!bye
    :: tcp2net[ALICE]?ok, bye -> net2tcp[BOB]!ok, bye
    :: tcp2net[PROXY]?invite -> net2tcp[BOB]!invite
    :: tcp2net[PROXY]?ringing -> net2tcp[ALICE]!ringing
    :: tcp2net[PROXY]?trying -> net2tcp[ALICE]!trying
    :: tcp2net[PROXY]?ok, invite -> net2tcp[ALICE]!ok, invite
    :: tcp2net[PROXY]?cancel -> net2tcp[ALICE]!cancel
    :: tcp2net[PROXY]?error -> net2tcp[ALICE]!error
    :: tcp2net[BOB]?msg -> net2tcp[ALICE]!msg
    :: tcp2net[BOB]?ringing -> net2tcp[PROXY]!ringing
    :: tcp2net[BOB]?ok, invite -> net2tcp[PROXY]!ok, invite
    :: tcp2net[BOB]?bye -> net2tcp[ALICE]!bye
    :: tcp2net[BOB]?ok, bye -> net2tcp[ALICE]!ok, bye
    :: tcp2net[BOB]?cancel -> net2tcp[PROXY]!cancel
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
