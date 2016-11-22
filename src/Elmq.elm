effect module Elmq
    where { command = MyCmd, subscription = MySub }
    exposing
        ( send
        , sendString
        , sendFloat
        , sendInt
        , sendBool
        , sendNaked
        , listen
        , listenString
        , listenFloat
        , listenInt
        , listenBool
        , listenNaked
        , decode
        )

{-|
Copyright (c) 2015, Gusztáv Szikszai All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list
of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

===

This is a module for publishing and subscribing to arbritary data in
different channels that are identified by strings.
# Listining
@docs listen, listenString, listenFloat, listenInt, listenBool, listenNaked
# Sending Data
@docs send, sendString, sendFloat, sendInt, sendBool, sendNaked
# Decodeing
@docs decode
-}

import Json.Decode exposing (Value)
import Json.Encode as JE
import Task exposing (Task)


{-| Representation of a command.
-}
type MyCmd msg
    = Send String Value


{-| Representation of a subscription.
-}
type MySub msg
    = Listen String (Value -> msg)


{-| Sends the given value to the given channel.
    Elmq.send "channelId" (Json.string "test")
-}
send : String -> Value -> Cmd msg
send id value =
    command (Send id value)


{-| Sends a _naked message_ (without value) to the given channel. This is used
generally to trigger actions.
    Elmq.send "channelId"
-}
sendNaked : String -> Cmd msg
sendNaked id =
    command (Send id JE.null)


{-| Sends a string value to the given channel.
    Elmq.sendString "channelId" "test"
-}
sendString : String -> String -> Cmd msg
sendString id value =
    send id (JE.string value)


{-| Sends a float value to the given channel.
    Elmq.sendFloat "channelId" 0.42
-}
sendFloat : String -> Float -> Cmd msg
sendFloat id value =
    send id (JE.float value)


{-| Sends a integer value to the given channel.
    Elmq.sendInt "channelId" 10
-}
sendInt : String -> Int -> Cmd msg
sendInt id value =
    send id (JE.int value)


{-| Sends a boolean value to the given channel.
    Elmq.sendBool "channelId" 10
-}
sendBool : String -> Bool -> Cmd msg
sendBool id value =
    send id (JE.bool value)


{-| Creates a subscription for the given channel.
    Elmq.listen "channelId" HandleValue
-}
listen : String -> (Value -> msg) -> Sub msg
listen id tagger =
    subscription (Listen id tagger)


{-| Creates a subscription for the given channel.
    Elmq.listenNaked "channelId" NakedMsg
-}
listenNaked : String -> msg -> Sub msg
listenNaked id msg =
    listen id (\_ -> msg)


{-| Creates a subscription for the given string channel.
    Elmq.listenString "channelId" HandleString
-}
listenString : String -> (String -> msg) -> Sub msg
listenString id tagger =
    listen id (decodeString "" tagger)


{-| Creates a subscription for the given float channel.
    Elmq.listenFloat "channelId" HandleFloat
-}
listenFloat : String -> (Float -> msg) -> Sub msg
listenFloat id tagger =
    listen id (decodeFloat 0 tagger)


{-| Creates a subscription for the given integer channel.
    Elmq.listenInt "channelId" HandleInt
-}
listenInt : String -> (Int -> msg) -> Sub msg
listenInt id tagger =
    listen id (decodeInt 0 tagger)


{-| Creates a subscription for the given boolean channel.
    Elmq.listenBool "channelId" HandleInt
-}
listenBool : String -> (Bool -> msg) -> Sub msg
listenBool id tagger =
    listen id (decodeBool False tagger)


{-| Decodes a Json value and maps it to a message with a fallback value.
    Elmq.decode Json.Decode.string "" HandleString value
-}
decode : Json.Decode.Decoder value -> value -> (value -> msg) -> Value -> msg
decode decoder default msg value =
    Json.Decode.decodeValue decoder value
        |> Result.withDefault default
        |> msg


{-| Decodes a Json string and maps it to a message with a fallback value.
-}
decodeString : String -> (String -> msg) -> Value -> msg
decodeString default msg =
    decode Json.Decode.string default msg


{-| Decodes a Json float and maps it to a message with a fallback value.
-}
decodeFloat : Float -> (Float -> msg) -> Value -> msg
decodeFloat default msg =
    decode Json.Decode.float default msg


{-| Decodes a Json integer and maps it to a message with a fallback value.
-}
decodeInt : Int -> (Int -> msg) -> Value -> msg
decodeInt default msg =
    decode Json.Decode.int default msg


{-| Decodes a Json boolean and maps it to a message with a fallback value.
-}
decodeBool : Bool -> (Bool -> msg) -> Value -> msg
decodeBool default msg =
    decode Json.Decode.bool default msg



-- Effect related


{-| Maps a command to an other command.
-}
cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap _ (Send id value) =
    Send id value


{-| Maps a subsctiption to an other subscription.
-}
subMap : (a -> b) -> MySub a -> MySub b
subMap func sub =
    case sub of
        Listen id tagger ->
            Listen id (tagger >> func)


{-| Representation of message (dummy).
-}
type Msg
    = Msg


{-| Representation of a state.
-}
type alias State =
    {}


{-| Initializes a state.
-}
init : Task Never State
init =
    Task.succeed {}


{-| On effects send values to listeners.
-}
onEffects : Platform.Router msg Msg -> List (MyCmd msg) -> List (MySub msg) -> State -> Task Never State
onEffects router commands subscriptions model =
    let
        {- Filter subscriptions and send messages to listeners. -}
        sendCommandMessages (Send id value) =
            List.filter (\(Listen subId _) -> subId == id) subscriptions
                |> List.map (send id value)

        {- Actually send messages to the app. -}
        send targetId value (Listen id tagger) =
            Platform.sendToApp router (tagger value)

        {- Get a list of tasks to execute. -}
        tasks =
            List.map sendCommandMessages commands
                |> List.foldr (++) []
    in
        {- Execute tasks and return the state -}
        Task.sequence tasks `Task.andThen` (\_ -> Task.succeed model)


{-| On self message do nothing because we don't receive these.
-}
onSelfMsg : Platform.Router msg Msg -> Msg -> State -> Task Never State
onSelfMsg router message model =
    Task.succeed model
