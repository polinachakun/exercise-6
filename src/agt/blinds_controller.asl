// blinds controller agent

/* Initial beliefs */

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Blinds (was:Blinds)
td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Blinds", "https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/blinds.ttl").

// the agent initially believes that the blinds are "lowered"
blinds("lowered").

/* Initial goals */ 

// The agent has the goal to start
!start.

/*
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agents believes that a WoT TD of a was:Blinds is located at Url
 * Body: greets the user
 */
@start_plan
+!start : td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Blinds", Url) <-
    .print("Blinds Controller starting...");
    makeArtifact("blinds", 
                 "org.hyperagents.jacamo.artifacts.wot.ThingArtifact",
                 [Url], MqttId);
    focus(MqttId);
    -+blinds("lowered").

@raise_blinds_plan
+!raise_blinds : true <-
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState",
                 ["raised"]);
    .print("Blinds raised");
    -+blinds("lowered");
    +blinds("raised");
     .send("personal_assistant", tell, blinds("raised")).

@lower_blinds_plan
+!lower_blinds : true <-
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState",
                 ["lowered"]);
    .print("Blinds lowered");
    -+blinds("raised");
    +blinds("lowered");
     .send("personal_assistant", tell, blinds("lowered")).

/* Reaction to CFP for increasing illuminance */
+cfp("inc-illuminance")[source(Source)] : blinds("lowered") <-
    .print("Received CFP for increasing illuminance from ", Source);
    .print("Blinds are lowered, proposing to raise them");
    .send(Source, tell, proposal("blinds_controller", "natural_light")).

+cfp("inc-illuminance")[source(Source)] : blinds("raised") <-
    .print("Received CFP for increasing illuminance from ", Source);
    .print("Blinds already raised, refusing");
    .send(Source, tell, refuse("inc-illuminance")).

/* Reaction to proposal acceptance/rejection */
+accept_proposal("natural_light")[source(Source)] <-
    .print("Proposal accepted by ", Source, ". Raising blinds");
    !raise_blinds.

+reject_proposal("natural_light")[source(Source)] <-
    .print("Proposal rejected by ", Source, ". No action needed").
