// personal assistant agent

broadcast(jason).

/* Initial goals */ 

// The agent has the goal to start
!start.

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: true (the plan is always applicable)
 * Body: greets the user
*/
+!start : true <-
    .print("Personal assistant starting...");
    .my_name(Name);
    makeArtifact("mqtt_PA", "room.MQTTArtifact", [Name], MqttId);
    focus(MqttId);
    .print("Personal Assistant: MQTT artifact created and focused").
     
 
 /* Plan to send a message using the internal operation defined in the artifact */
 +!send_message(Sender, Performative, Content) : true <-
     sendMsg(Sender, Performative, Content).
     
 
 /*
  * Plan to handle observable changes in the artifact
  * Triggered when the "received_message" observable property is added.
  */
 @handle_received_message
 +received_message(Sender, Performative, Content) : true <-
     println("Personal Assistant Message received from ", Sender, " with content: ", Content).
     
 
 /* Plan for selective broadcasting */
 @selective_broadcast_plan
 +!selective_broadcast(Sender, Performative, Content) : broadcast(mqtt) <-
     !add_message(Sender, Performative, Content).
     
 
 +!selective_broadcast(Sender, Performative, Content) : broadcast(jason) <-
     .broadcast(Performative, message(Sender, Performative, Content));
     println("Personal Assistant Broadcasted via Jason: ", Content).
     

/*
 * Plan for checking if we need to wake up the user
 * Triggered when relevant conditions change
 */
+!check_wake_up_conditions : owner_state("asleep") & upcoming_event(Event) & Event \== none <-
    .print("User is asleep but has an upcoming event: ", Event);
    !wake_up_user.


/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }