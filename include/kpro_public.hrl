%%%   Copyright (c) 2017, Klarna AB
%%%
%%%   Licensed under the Apache License, Version 2.0 (the "License");
%%%   you may not use this file except in compliance with the License.
%%%   You may obtain a copy of the License at
%%%
%%%       http://www.apache.org/licenses/LICENSE-2.0
%%%
%%%   Unless required by applicable law or agreed to in writing, software
%%%   distributed under the License is distributed on an "AS IS" BASIS,
%%%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%%   See the License for the specific language governing permissions and
%%%   limitations under the License.

-ifndef(KPRO_PUBLIC_HRL_).
-define(KPRO_PUBLIC_HRL_, true).

%% For applications on top of kafka client (brod).

-record(kafka_message,
        { offset :: kpro:offset()
        , magic_byte :: kpro:int8()
        , attributes :: kpro:int8()
        , key :: kpro:bytes()
        , value :: kpro:bytes()
        , crc :: non_neg_integer() %% not kpro:int32() because it's unsigned
        , ts_type :: kpro:timestamp_type()
        , ts :: kpro:int64()
        }).

-endif.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
