mtype = {msg, ack, invite, bye, cancel, trying, ringing, ok, error}

#define QSZ 1
#define AP 0
#define AB 1
#define PB 2
#define PA 3
#define BA 4
#define BP 5

chan sip2tcp[6] = [QSZ] of {mtype};
chan tcp2sip[6] = [QSZ] of {mtype};
chan tcp2net[6] = [QSZ] of {mtype, mtype, bit};
chan net2tcp[6] = [QSZ] of {mtype, mtype, bit};

proctype alice() {
   sip2tcp[AP]!invite;
   do
   :: tcp2sip[AP]?trying
   :: tcp2sip[AP]?ringing
   :: tcp2sip[AP]?ok -> sip2tcp[AB]!ack; break
   :: tcp2sip[AP]?cancel -> goto end
   :: tcp2sip[AP]?error -> goto end
   od;
   sip2tcp[AB]!bye;
   tcp2sip[AB]?ok;

end:
}

proctype proxy() {
end:
   do
   :: tcp2sip[PA]?invite ->
      sip2tcp[PA]!trying;
      if
      :: sip2tcp[PB]!invite
      :: sip2tcp[PA]!error
      fi
   :: tcp2sip[PB]?ringing -> sip2tcp[PA]!ringing
   :: tcp2sip[PB]?ok -> sip2tcp[PA]!ok
   :: tcp2sip[PB]?cancel -> sip2tcp[PA]!cancel
   od
}

proctype bob() {
end_not_invited:
   tcp2sip[BP]?invite;
   sip2tcp[BP]!ringing;
   if
   :: sip2tcp[BP]!ok -> skip
   :: sip2tcp[BP]!cancel -> goto end
   fi;
   tcp2sip[BA]?ack;
   tcp2sip[BA]?bye;
   sip2tcp[BA]!ok;

end:
}

proctype tcps(byte id) {
   mtype sip;
   bit b, s;

end:
   sip2tcp[id]?sip;

sending:
   tcp2net[id]!msg, sip, s;
   if
   :: net2tcp[id]?ack, _, b ->
      if
      :: b == s -> s = 1 - s; goto end
      :: b != s -> goto sending
      fi
   :: timeout -> goto sending
   fi
}

proctype tcpr(byte id) {
   mtype sip;
   bit b, r;

end:
   do
   :: net2tcp[id]?msg, sip, b;
      tcp2net[id]!ack, 0, b;
      if
      :: b == r -> r = 1 - r; tcp2sip[id]!sip
      :: b != r -> skip
      fi
   od
}

proctype net() {
   mtype tcp, sip;
   bit r;

end:
   do
   :: tcp2net[AP]?tcp, sip, r ->
      if
      :: net2tcp[PA]!tcp, sip, r
      :: skip
      fi
   :: tcp2net[AB]?tcp, sip, r ->
      if
      :: net2tcp[BA]!tcp, sip, r
      :: skip
      fi
   :: tcp2net[PA]?tcp, sip, r ->
      if
      :: net2tcp[AP]!tcp, sip, r
      :: skip
      fi
   :: tcp2net[PB]?tcp, sip, r ->
      if
      :: net2tcp[BP]!tcp, sip, r
      :: skip
      fi
   :: tcp2net[BA]?tcp, sip, r ->
      if
      :: net2tcp[AB]!tcp, sip, r
      :: skip
      fi
   :: tcp2net[BP]?tcp, sip, r ->
      if
      :: net2tcp[PB]!tcp, sip, r
      :: skip
      fi
   od
}

init {
   run net();
   run tcps(AP);
   run tcpr(AP);
   run tcps(AB);
   run tcpr(AB);
   run tcps(PA);
   run tcpr(PA);
   run tcps(PB);
   run tcpr(PB);
   run tcps(BA);
   run tcpr(BA);
   run tcps(BP);
   run tcpr(BP);
   run alice();
   run proxy();
   run bob();
}

#define TWIN(x) (((x)+3)%6)

byte proc;
mtype x;

ltl { [] (sip2tcp[proc]?[x]) -> (<> tcp2sip[TWIN(proc)]?[x]) }
