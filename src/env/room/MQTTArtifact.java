package room;

import cartago.Artifact;
import cartago.INTERNAL_OPERATION;
import cartago.OPERATION;

import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;

/**
 * A CArtAgO artifact providing MQTT messaging to agents.
 */
public class MQTTArtifact extends Artifact {

    private MqttClient client;
    private final String[] brokers = {
        "tcp://broker.hivemq.com:1883",
        "tcp://test.mosquitto.org:1883"
    };
    
    private String clientId;
    private final String topic = "was-exercise-6/communication-polina";
    private final int qos = 2;
    private boolean connected = false;

    /**
     * Initialization of the artifact. This is the method CArtAgO expects to call during makeArtifact.
     */
    public void init(String name) {
        log("Initializing MQTTArtifact with name: " + name);
        this.clientId = name;
        
        // Define initial observable property
        defineObsProperty("connected", false);
        
        // Try to connect to MQTT broker in a separate operation to avoid blocking init
        execInternalOp("tryConnect");
    }

    /**
     * Internal operation to attempt MQTT connection without blocking init
     */
    @INTERNAL_OPERATION
    void tryConnect() {
        try {
            // Try each broker in the list
            for (String broker : brokers) {
                if (connectToBroker(broker)) {
                    return;
                }
            }
            
            // If all connection attempts fail
            log("Failed to connect to any MQTT broker. The artifact will continue to operate with limited functionality.");
            
        } catch (Exception e) {
            e.printStackTrace();
            log("MQTT connection failed: " + e.getMessage());
        }
    }
    
    /**
     * Attempts to connect to a specific broker
     * @return true if connection successful, false otherwise
     */
    private boolean connectToBroker(String brokerUrl) {
        try {
            log("Attempting to connect to MQTT broker: " + brokerUrl);
            
            // Use MemoryPersistence for better reliability
            this.client = new MqttClient(brokerUrl, clientId, new MemoryPersistence());

            // Configure connection options
            MqttConnectOptions connOpts = new MqttConnectOptions();
            connOpts.setCleanSession(true);
            connOpts.setKeepAliveInterval(60);
            connOpts.setAutomaticReconnect(true);
            connOpts.setConnectionTimeout(10); // 10 seconds timeout

            // Set callback
            client.setCallback(new MQTTCallbackImpl());

            // Connect and subscribe
            client.connect(connOpts);
            client.subscribe(topic, qos);

            // Update observable property for connection status
            connected = true;
            updateObsProperty("connected", true);
            log(String.format("[%s] Successfully connected to %s", clientId, brokerUrl));
            return true;

        } catch (Exception e) {
            log("Failed to connect to broker " + brokerUrl + ": " + e.getMessage());
            return false;
        }
    }

    @OPERATION
    public void sendMsg(String agent, String performative, String content) {
        if (!connected || client == null) {
            log("Cannot send message: not connected to MQTT broker");
            return;
        }
        
        try {
            String message = agent + "," + performative + "," + content;
            MqttMessage mqttMessage = new MqttMessage(message.getBytes());
            mqttMessage.setQos(qos);
            client.publish(topic, mqttMessage);
            log(String.format("[%s] Message sent: %s", clientId, message));
        } catch (Exception e) {
            e.printStackTrace();
            log("Failed to send message: " + e.getMessage());
        }
    }

    @INTERNAL_OPERATION
    public void addMessage(String agent, String performative, String content) {
        if ("tell".equalsIgnoreCase(performative)) {
            defineObsProperty("received_message", agent, performative, content);
            log(String.format("[%s] Observable message from %s: %s", clientId, agent, content));
        } else {
            log(String.format("[%s] Unsupported performative: %s", clientId, performative));
        }
    }

    private class MQTTCallbackImpl implements MqttCallback {
        @Override
        public void connectionLost(Throwable cause) {
            log(String.format("[%s] Connection lost: %s", clientId, cause.getMessage()));
            try {
                connected = false;
                updateObsProperty("connected", false);
                
                // Try to reconnect in a new thread to avoid blocking
                Thread reconnectThread = new Thread(() -> {
                    try {
                        execInternalOp("tryConnect");
                    } catch (Exception e) {
                        log("Failed to reconnect: " + e.getMessage());
                    }
                });
                reconnectThread.setDaemon(true);
                reconnectThread.start();
                
            } catch (Exception e) {
                log("Failed to update 'connected' property after loss: " + e.getMessage());
            }
        }

        @Override
        public void messageArrived(String topic, MqttMessage message) {
            try {
                String payload = new String(message.getPayload());
                log(String.format("[%s] Message received: %s", clientId, payload));
                String[] parts = payload.split(",", 3);
                if (parts.length == 3) {
                    execInternalOp("addMessage", parts[0], parts[1], parts[2]);
                } else {
                    log("Invalid message format: " + payload);
                }
            } catch (Exception e) {
                log("Failed to process received message: " + e.getMessage());
            }
        }

        @Override
        public void deliveryComplete(IMqttDeliveryToken token) {
            // No-op or optionally log delivery completion
        }
    }
}