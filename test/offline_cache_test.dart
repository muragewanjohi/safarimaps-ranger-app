import 'package:flutter_test/flutter_test.dart';
import 'package:ranger/data/models/dashboard_models.dart';

void main() {
  group('Offline Cache Models JSON Serialization', () {
    test('NewLocationInput toJson and fromJson matches specification', () {
      const input = NewLocationInput(
        category: 'Attractions',
        subcategory: 'Watering Hole',
        description: 'A place where animals drink water.',
        coordinates: '-1.3456, 36.7890',
        count: '15',
        attractionName: 'Main Pool',
        operatingHours: '6 AM - 6 PM',
        hotelName: 'Watering Lodge',
        contact: '+254700000000',
        bestTimeToVisit: 'Evening',
        photos: ['photo1.jpg', 'photo2.jpg'],
      );

      final json = input.toJson();
      expect(json['category'], 'Attractions');
      expect(json['subcategory'], 'Watering Hole');
      expect(json['description'], 'A place where animals drink water.');
      expect(json['coordinates'], '-1.3456, 36.7890');
      expect(json['count'], '15');
      expect(json['attractionName'], 'Main Pool');
      expect(json['operatingHours'], '6 AM - 6 PM');
      expect(json['hotelName'], 'Watering Lodge');
      expect(json['contact'], '+254700000000');
      expect(json['bestTimeToVisit'], 'Evening');
      expect(json['photos'], ['photo1.jpg', 'photo2.jpg']);

      final parsed = NewLocationInput.fromJson(json);
      expect(parsed.category, input.category);
      expect(parsed.subcategory, input.subcategory);
      expect(parsed.description, input.description);
      expect(parsed.coordinates, input.coordinates);
      expect(parsed.count, input.count);
      expect(parsed.attractionName, input.attractionName);
      expect(parsed.operatingHours, input.operatingHours);
      expect(parsed.hotelName, input.hotelName);
      expect(parsed.contact, input.contact);
      expect(parsed.bestTimeToVisit, input.bestTimeToVisit);
      expect(parsed.photos, input.photos);
    });

    test('IncidentModel toJson maps properties', () {
      const incident = IncidentModel(
        id: '123',
        title: 'Poaching Alert',
        category: 'Security',
        severity: 'Critical',
        status: 'Reported',
        description: 'Poachers spotted near Sector A.',
        coordinates: '-1.456, 36.901',
        touristsAffected: 0,
        tourOperator: 'None',
        contactInfo: 'N/A',
        transport: 'Foot',
        medicalCondition: 'N/A',
        tags: ['security', 'poaching'],
        photos: ['pic1.jpg'],
        createdAt: '2026-05-27T12:00:00Z',
        reportedBy: 'ranger_1',
        reportedByName: 'John Doe',
        parkId: 'nairobi_national_park',
        location: 'Sector A Gate',
      );

      final json = incident.toJson();
      expect(json['id'], '123');
      expect(json['title'], 'Poaching Alert');
      expect(json['category'], 'Security');
      expect(json['severity'], 'Critical');
      expect(json['status'], 'Reported');
      expect(json['description'], 'Poachers spotted near Sector A.');
      expect(json['coordinates'], '-1.456, 36.901');
      expect(json['tourists_affected'], 0);
      expect(json['operator'], 'None');
      expect(json['contact_info'], 'N/A');
      expect(json['transport'], 'Foot');
      expect(json['medical_condition'], 'N/A');
      expect(json['tags'], ['security', 'poaching']);
      expect(json['photos'], ['pic1.jpg']);
      expect(json['created_at'], '2026-05-27T12:00:00Z');
      expect(json['reported_by'], 'ranger_1');
      expect(json['reported_by_name'], 'John Doe');
      expect(json['park_id'], 'nairobi_national_park');
      expect(json['location'], 'Sector A Gate');
    });

    test('IncidentNoteModel toJson and fromJson matches specification', () {
      const note = IncidentNoteModel(
        id: 'note_1',
        incidentId: 'incident_1',
        note: 'Stuck van successfully towed out of the mud.',
        createdBy: 'Sarah Johnson',
        createdAt: '2026-05-27T12:00:00Z',
      );

      final json = note.toJson();
      expect(json['id'], 'note_1');
      expect(json['incident_id'], 'incident_1');
      expect(json['note'], 'Stuck van successfully towed out of the mud.');
      expect(json['created_by'], 'Sarah Johnson');
      expect(json['created_at'], '2026-05-27T12:00:00Z');

      final parsed = IncidentNoteModel.fromJson(json);
      expect(parsed.id, note.id);
      expect(parsed.incidentId, note.incidentId);
      expect(parsed.note, note.note);
      expect(parsed.createdBy, note.createdBy);
      expect(parsed.createdAt, note.createdAt);
    });
  });
}
