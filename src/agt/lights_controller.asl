// lights controller agent

/* Initial beliefs */

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Lights (was:Lights)
td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Lights", "https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/lights.ttl").

// The agent initially believes that the lights are "off"
lights("off").

/* Initial goals */ 

// The agent has the goal to start
!start.

/*
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agents believes that a WoT TD of a was:Lights is located at Url
 * Body: greets the user
 */
@start_plan
+!start : td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Lights", Url) <-
    .print("Lights Controller starting...");
    makeArtifact("lights", 
                 "org.hyperagents.jacamo.artifacts.wot.ThingArtifact",
                 [Url], MqttId);
    focus(MqttId);
    -+lights("off").

@turn_on_plan
+!turn_lights_on : true <-
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState",
                 ["on"]);
    .print("Lights turned on");
    -+lights("off");
    +lights("on");
    .send("personal_assistant", tell, lights("on")).


@turn_off_plan
+!turn_lights_off : true <-
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState",
                 ["off"]);
    .print("Lights turned off");
    -+lights("on");
    +lights("off");
    .send("personal_assistant", tell, lights("off")).

// Reaction to CFP ещ increasу illuminance 
+cfp("inc-illuminance")[source(Source)] : lights("off") <-
    .print("Received CFP for increasing illuminance from ", Source);
    .print("Lights are off, proposing to turn them on");
    .send(Source, tell, proposal("lights_controller", "artificial_light")).

+cfp("inc-illuminance")[source(Source)] : lights("on") <-
    .print("Received CFP for increasing illuminance from ", Source);
    .print("Lights already on, refusing");
    .send(Source, tell, refuse("inc-illuminance")).

// Reaction to proposal accept/reject
+accept_proposal("artificial_light")[source(Source)] <-
    .print("Proposal accepted by ", Source, ". Turning lights on");
    !turn_lights_on.

+reject_proposal("artificial_light")[source(Source)] <-
    .print("Proposal rejected by ", Source, ". No action needed").