mtype = {msg, ack, invite, bye, cancel, trying, ringing, ok, error}

#define QSZ 2
#define AP 0
#define AB 1
#define PA 2
#define PB 3
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
   assert(true)
}

proctype proxy() {
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
   tcp2sip[BP]?invite;
   sip2tcp[BP]!ringing;
   if
   :: sip2tcp[BP]!ok -> skip
   :: sip2tcp[BP]!cancel -> goto end
   fi
   tcp2sip[BA]?ack;
   tcp2sip[BA]?bye;
   sip2tcp[BA]!ok;

end:
   assert(true)
}

proctype tcpSender(byte id) {
   mtype sipdata;
   bit b, s, r;

standby:
   sip2tcp[id]?sipdata;

sending:
   tcp2net[id]!msg, sipdata, s;
   if
   :: net2tcp[id]?ack, _, b ->
      if
      :: b == s -> s = 1 - s; goto standby
      :: b != s -> goto sending
      fi
   :: timeout -> goto sending
   fi
}

proctype tcpReceiver(byte id) {
   mtype sipdata;
   bit b, s, r;

   do
   :: net2tcp[id]?msg, sipdata, b;
      tcp2net[id]!ack, 0, b;
      if
      :: b == r -> r = 1 - r; tcp2sip[id]!sipdata
      :: b != r -> skip
      fi
   od;
}

proctype net() {
   mtype tcpdata, sipdata;
   bit r;
   do
   :: tcp2net[AP]?tcpdata, sipdata, r ->
      if
      :: net2tcp[PA]!tcpdata, sipdata, r
      :: skip
      fi
   :: tcp2net[AB]?tcpdata, sipdata, r ->
      if
      :: net2tcp[BA]!tcpdata, sipdata, r
      :: skip
      fi
   :: tcp2net[PA]?tcpdata, sipdata, r ->
      if
      :: net2tcp[AP]!tcpdata, sipdata, r
      :: skip
      fi
   :: tcp2net[PB]?tcpdata, sipdata, r ->
      if
      :: net2tcp[BP]!tcpdata, sipdata, r
      :: skip
      fi
   :: tcp2net[BA]?tcpdata, sipdata, r ->
      if
      :: net2tcp[AB]!tcpdata, sipdata, r
      :: skip
      fi
   :: tcp2net[BP]?tcpdata, sipdata, r ->
      if
      :: net2tcp[PB]!tcpdata, sipdata, r
      :: skip
      fi
   od
}

init {
   run net();
   run tcpSender(AP);
   run tcpReceiver(AP);
   run tcpSender(AB);
   run tcpReceiver(AB);
   run tcpSender(PA);
   run tcpReceiver(PA);
   run tcpSender(PB);
   run tcpReceiver(PB);
   run tcpSender(BA);
   run tcpReceiver(BA);
   run tcpSender(BP);
   run tcpReceiver(BP);
   run alice();
   run proxy();
   run bob();
}
