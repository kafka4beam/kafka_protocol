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

-record(kafka_message,
        { offset :: kpro:offset()
        , magic_byte :: kpro:magic()
        , attributes :: kpro:int8()
        , key :: kpro:bytes()
        , value :: kpro:bytes()
        , crc :: non_neg_integer() %% not kpro:int32() because it's unsigned
               | undefined %% since magic 2, there is no per-message crc
        , ts_type :: undefined %% magic 0
                   | kpro:timestamp_type()  %% since magic 1
        , ts :: undefined %% magic 0
              | kpro:int64() %% since magic 1
        , headers :: undefined %% magic 0-1
                   | kpro:headers() %% since magic 2
        }).

-endif.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
