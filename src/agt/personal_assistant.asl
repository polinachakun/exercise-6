// personal assistant agent

broadcast(jason).

// Task 4.2 wake up preferences
wake_up_preference("natural_light", 0).
wake_up_preference("artificial_light", 1).

/* Initial goals */ 
!initialize.
!start.


// Master initialization plan
+!initialize : true <-
    !initialize_wake_up_preferences.

// Initialize user preferences for wake-up
+!initialize_wake_up_preferences : true <-
    .print("Initializing user preferences for wake-up...");
    +user_pref(natural_light, 0);    // Most preferred 
    +user_pref(artificial_light, 1);
    .print("User wake up preferences initialized.").

// Start the personal assistant
+!start : true <-
    .print("Personal assistant starting...");
    .my_name(Name);
    makeArtifact("mqtt_PA", "room.MQTTArtifact", [Name], MqttId);
    focus(MqttId);
    .print("Personal Assistant: MQTT artifact created and focused").


 /* Plan to send message using artifact operation*/
+!send_message(Sender, Performative, Content) : true <-
    sendMsg(Sender, Performative, Content).

 /*
  * Plan to handle observable changes in the artifact
  * Triggered when the "received_message" observable property is added.
  */
+received_message(Sender, Performative, Content) : true <-
    println("Personal Assistant Message received from ", Sender, " with content: ", Content).
     

/* Plan for selective broadcasting via MQTT */
+!selective_broadcast(Sender, Performative, Content) : broadcast(mqtt) <-
    sendMsg("all", Performative, Content);
    .print("Personal Assistant Broadcasted via MQTT: ", Content).

/* Plan for selective broadcasting via Jason */  
+!selective_broadcast(Sender, Performative, Content) : broadcast(jason) <-
    .broadcast(Performative, message(Sender, Performative, Content));
    .print("Personal Assistant Broadcasted via Jason: ", Content).


/* Task 4.1 Plan to react when there's an upcoming event and user is awake  */
+upcoming_event("now") : owner_state("awake") <-
    .println("Enjoy your event!").

/* Task 4.1 Plan to react when there's an upcoming event and user is asleep */
+upcoming_event("now") : owner_state("asleep") <-
    .println("User asleep & event now → starting wake‑up CNP");
    !clear_cnp_data;
    !initiate_wakeup.

/*
 * Plan for checking if we need to wake up the user
 * Triggered when relevant conditions change
 */
+!check_wake_up_conditions : owner_state("asleep") & upcoming_event(Event) & Event \== none <-
    .print("User is asleep but has an upcoming event: ", Event);
    !wake_up_user.

// Plan to clear any existing CNP data
+!clear_cnp_data : true <-
    .abolish(received_proposal(_,_));
    .abolish(proposal(_,_)).

//  Plan to initiate the wakeup process 
+!initiate_wakeup : true <-
    .println("Initiating wake-up process");
    !wake_up_user.

// Wake up user using CNP via MQTT
+!wake_up_user : broadcast(mqtt) <-
    .print("Initiating Contract Net Protocol via MQTT");
    sendMsg("all", tell, cfp("inc-illuminance"));
    .wait(2000);  // Wait for proposals
    !evaluate_proposals.

/* Plan to wake up the user using Contract Net Protocol via Jason */
+!wake_up_user : broadcast(jason) <-
    .print("Initiating Contract Net Protocol via Jason");
    .broadcast(tell, cfp("inc-illuminance"));
    .wait(2000); 
    !evaluate_proposals.

/* Handle proposals from controllers */
+proposal(Agent, Service)[source(Source)] <-
    .print("Received proposal from ", Source, " for service: ", Service);
    +received_proposal(Source, Service).

/* Handle refusals */
+refuse("inc-illuminance")[source(Source)] <-
    .print("Received refusal from ", Source, " for increasing illuminance").

/* Plan to evaluate received proposals */
+!evaluate_proposals : true <-
    .findall(proposal(A,S), received_proposal(A,S), Proposals);
    .print("Evaluating proposals: ", Proposals);
    .length(Proposals, Count);
    
    if (Count == 0) {
        .print("No proposals received");
        !ask_friend_for_help;
    } else {
        !process_proposals(Proposals);
    }.

// Process proposals systematically
+!process_proposals(Proposals) : true <-
    // Check for natural light proposal
    if (.member(proposal(AgentNat, "natural_light"), Proposals)) {
        .print("Accepting natural_light from ", AgentNat);
        .send(AgentNat, tell, accept_proposal("natural_light"));
        .wait(1500);  
    }
  
    // Check for artificial light proposal
    if (.member(proposal(AgentArt, "artificial_light"), Proposals)) {
        .print("Accepting artificial_light from ", AgentArt);
        .send(AgentArt, tell, accept_proposal("artificial_light"));
    }.

/* Select the best proposal based on user preferences */
+!select_best_proposal(Proposals) : wake_up_preference("natural_light", NatRank) & 
                                   wake_up_preference("artificial_light", ArtRank) & 
                                   NatRank < ArtRank <-
    // Try to find natural light proposal 
    if (.member(proposal(Agent, "natural_light"), Proposals)) {
        .print("Accepting proposal from ", Agent, " for natural light (most preferred)");
        .send(Agent, tell, accept_proposal("natural_light"));

        !reject_other_proposals(Agent);
    } else {
        // Try artificial light
        .member(proposal(Agent, "artificial_light"), Proposals);
        .print("Natural light proposal not found. Accepting proposal from ", Agent, " for artificial light");
        .send(Agent, tell, accept_proposal("artificial_light"));
    
        !reject_other_proposals(Agent);
    }.

/* Select the best proposal based on user preferences - artificial light preferred */
+!select_best_proposal(Proposals) : wake_up_preference("natural_light", NatRank) & 
                                   wake_up_preference("artificial_light", ArtRank) & 
                                   ArtRank < NatRank <-
    // Try to find an artificial light proposal (most preferred)
    if (.member(proposal(Agent, "artificial_light"), Proposals)) {
        .print("Accepting proposal from ", Agent, " for artificial light (most preferred)");
        .send(Agent, tell, accept_proposal("artificial_light"));

        !reject_other_proposals(Agent);
    } else {
        // If no artificial light proposal, try natural light
        .member(proposal(Agent, "natural_light"), Proposals);
        .print("Artificial light proposal not found. Accepting proposal from ", Agent, " for natural light");
        .send(Agent, tell, accept_proposal("natural_light"));

        !reject_other_proposals(Agent);
    }.

// If preferred method not found, try any available one
+!select_best_proposal(Proposals) <-
    .member(proposal(Agent, Service), Proposals);
    .print("Accepting proposal from ", Agent, " for ", Service);
    .send(Agent, tell, accept_proposal(Service));

    !reject_other_proposals(Agent).

// Handle empty proposals list
+!select_best_proposal([]) <-
    .print("No available proposals");
    !ask_friend_for_help.

// Reject all proposals except the accepted one
+!reject_other_proposals(AcceptedAgent) <-
    .findall(OtherAgent, received_proposal(OtherAgent, _) & OtherAgent \== AcceptedAgent, OtherAgents);
    for (.member(OtherAgent, OtherAgents)) {
        .findall(Service, received_proposal(OtherAgent, Service), Services);
        for (.member(Service, Services)) {
            .print("Rejecting proposal from ", OtherAgent, " for ", Service);
            .send(OtherAgent, tell, reject_proposal(Service));
        }
    }.
    

/* Plan to ask friend for help when no proposals are received */
+!ask_friend_for_help <-
    .print("No proposals received, asking friend for help");
    if (broadcast(mqtt)) {
        .print("Sending help request via MQTT");
        sendMsg("friend", tell, "Please wake up our friend, they have an important event but are still asleep");
    } else {
        .println("Sending help request via Jason");
        .send("friend", tell, message("personal_assistant", tell, "Please wake up our  friend, they have an important event but are still asleep"));
    }
    .print("Friend notification sent").

/* Plan for turning on lights - sends request to lights_controller */
+!turn_lights_on : true <-
    .print("Attempting to turn on lights");
    .send(lights_controller, achieve, turn_lights_on).

/* Plan for raising blinds - sends request to blinds_controller */
+!raise_blinds : true <-
    .print("Attempting to raise blinds");
    .send(blinds_controller, achieve, raise_blinds).

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }