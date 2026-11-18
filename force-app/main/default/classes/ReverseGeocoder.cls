/**
 * Turns coordinates into a readable address. Implement this interface to use another
 * provider (Google, Mapbox, an internal service) and set it in InterventionController.geocoder.
 */
public interface ReverseGeocoder {
    /** Returns the address, or null when none is found. */
    String toAddress(Decimal latitude, Decimal longitude);
}
