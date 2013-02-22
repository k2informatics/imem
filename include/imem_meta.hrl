
-include("imem_if.hrl").

-type ddEntityId() :: 	reference() | integer() | atom().
-type ddType() ::		atom() | tuple() | list().         %% term | list | tuple | integer | float | binary | string | ref | pid | ipaddr                  

-record(ddColumn,                           %% column definition    
                  { name                    ::atom()
                  , type = term             ::ddType()
                  , len = 0  	              ::integer()
                  , prec = 0		        ::integer()
                  , default                 ::any()
                  , opts = []               ::list()
                  }
        ).

-record(ddTable,                            %% table    
                  { qname                   ::{atom(),atom()}		%% {Schema,Table}
                  , columns                 ::list(#ddColumn{})
                  , opts = []               ::list()      
                  , owner=system            ::ddEntityId()        	%% AccountId of creator / owner
                  , readonly='false'        ::'true' | 'false'
                  }
       ).
-define(ddTable, [tuple,list,list,userid,boolean]).

-define(nav, '$not_a_value').    %% used as default value which must not be used (not null columns)
-define(nac, '$not_a_column').   %% used as value column name for key only tables

-record(dual,                               %% table    
                  { dummy = "X"             ::list()        % fixed string "X"
                  , nac = ?nav              ::atom()        % not a column
                  }
       ).
-define(dual, [string,atom]).

-define(OneWeek, 7.0).                      %% span of  datetime or timestamp (fraction of 1 day)
-define(OneDay, 1.0).                       %% span of  datetime or timestamp (fraction of 1 day)
-define(OneHour, 0.041666666666666664).     %% span of  datetime or timestamp (1.0/24.0 of 1 day)
-define(OneMinute, 6.944444444444444e-4).   %% span of  datetime or timestamp (1.0/24.0 of 1 day)
-define(OneSecond, 1.1574074074074073e-5).  %% span of  datetime or timestamp (fraction of 1 day)

-define(DataTypes,[ 'fun' 
                  , atom
                  , binary
                  , binstr
                  , boolean
                  , datetime
                  , decimal
                  , float
                  , integer
                  , ipaddr
                  , list
                  , pid
                  , ref
                  , string
                  , term
                  , timestamp
                  , tuple
                  , userid
                  ]).
