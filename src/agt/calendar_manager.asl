// calendar manager agent

/* Initial beliefs */

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://was-course.interactions.ics.unisg.ch/wake-up-ontology#CalendarService (was:CalendarService)
td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#CalendarService", "https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/calendar-service.ttl").

/* Initial goals */ 

// The agent has the goal to start
!start.

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agents believes that a WoT TD of a was:CalendarService is located at Url
 * Body: greets the user
 */
@start_plan
+!start : td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#CalendarService", Url) <-
    .print("Calendar manager starting...");
    makeArtifact("calendar", 
                 "org.hyperagents.jacamo.artifacts.wot.ThingArtifact",
                 [Url], MqttId);
    !read_upcoming_event.


@read_upcoming_event_plan
+!read_upcoming_event : true <-
    readProperty("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#ReadUpcomingEvent",
                 EventList);
    .nth(0, EventList, Event);
    .print("Upcoming event: ", Event);
    .send("personal_assistant", tell, upcoming_event(Event));
    .wait(5000);
    !read_upcoming_event.
