// Kafka Streams Skeleton for TicketSoon Pilot

import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.KTable;
import org.apache.kafka.streams.kstream.TimeWindows;
import org.apache.kafka.streams.kstream.Materialized;

public class TicketSoon {
  public static void main(String[] args) {
    StreamsBuilder builder = new StreamsBuilder();

    // Consume enriched events
    KStream<String, Event> ev = builder.stream("events.enriched");

    // Aggregate features in 15-minute windows
    KTable<Windowed<String>, Features> feat = ev
      .groupByKey()
      .windowedBy(TimeWindows.of(Duration.ofMinutes(15)))
      .aggregate(Features::init, (k, e, f) -> f.update(e),
        Materialized.as("features-store"));

    // Score windows and generate TicketSoon signals
    KStream<String, Score> score = feat.toStream().mapValues(f -> {
      double s = 0.0;
      if (f.lagZ >= 2 && f.cdcRateHigh) s += 0.4;
      if (f.sigmaHigh && f.teProxy > 0) s += 0.4;
      if (f.errRateHigh && f.fanout >= 3) s += 0.3;
      if (f.ctrlDensityHigh && f.errTrendDown) s -= 0.3;

      if (s >= 0.7) {
        return new Score(s, f.reasons());
      } else {
        return null;
      }
    }).filter((svc, sc) -> sc != null);

    score.to("ops.earlywarn");

    KafkaStreams streams = new KafkaStreams(builder.build(), props);
    streams.start();
  }
}
