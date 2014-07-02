-include("imem_meta.hrl").

-record(loadControl,
                  { operation = channel     ::atom()
                  , state = stopped         ::atom()
                  , keyregex = <<".*">>     ::binary()
                  , limit = 1000 	        ::integer()                  
                  , readdelay = 0           ::integer()
                  }
        ).

-define(loadControl, [atom,atom,binstr,integer,integer]).

-record(loadOutput,
                  { operation = channel     ::atom()
                  , keycounter = 0          ::integer()
                  , keys = []               ::list()
                  , time                    ::any() 
                  , totalread = 0           ::integer()
                  , rate = 0                ::float()                  
                  , lastItem                ::any()
                  , lastValue               ::any()
                  }
        ).

-define(loadOutput, [atom,integer,list,timestamp,integer,float,term,term]).
