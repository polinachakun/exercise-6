package room;

import cartago.Artifact;
import cartago.INTERNAL_OPERATION;
import cartago.OPERATION;
import org.eclipse.paho.client.mqttv3.*;

/**
 * A CArtAgO artifact that provides an operation for sending messages to agents 
 * with KQML performatives using the dweet.io API
 */
public class MQTTArtifact extends Artifact {

    MqttClient client;
    String broker = "tcp://test.mosquitto.org:1883";
    String clientId; //TODO: Initialize in init method.
    String topic = "was-exercise-6/communication-jeremy"; //TODO: change topic name to make it specific to you.
    int qos = 2;

    public void init(String name){
        //TODO: subscribe to the right topic of the MQTT broker and add observable properties for perceived messages (using a custom MQTTCallack class, and the addMessage internal operation).
        //The name is used for the clientId.
    }

    @OPERATION
    public void sendMsg(String agent, String performative, String content){
        //TODO: complete operation to send messages
    }

    @INTERNAL_OPERATION
    public void addMessage(String agent, String performative, String content){
        //TODO: complete to add a new observable property.
    }

    //TODO: create a custom callback class from MQTTCallack to process received messages
    
}
