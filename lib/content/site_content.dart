import 'content.dart';

/// Everything the site says, in page order. Copy in brackets is
/// placeholder.
const List<Section> sections = [
  Section(
    id: SectionId.about,
    title: 'About',
    descriptor: '[Who I am]',
    entries: [Entry(title: '[About]', text: '[A short bio.]')],
  ),
  Section(
    id: SectionId.work,
    title: 'Work',
    descriptor: '13 tenants · 1M+ downloads',
    entries: [
      Entry(
        title: '[Project 01]',
        text: '[What it is, your part, one result.]',
      ),
      Entry(
        title: '[Project 02]',
        text: '[What it is, your part, one result.]',
      ),
    ],
  ),
  Section(
    id: SectionId.personal,
    title: 'Personal',
    descriptor: '[Side projects]',
    entries: [
      Entry(title: '[Project 01]', text: '[What it is and why.]'),
      Entry(title: 'This website', text: '[How it is made.]'),
    ],
  ),
  Section(
    id: SectionId.contact,
    title: 'CV & Contact',
    descriptor: '[CV, LinkedIn, GitHub, email]',
    entries: [Entry(title: 'Comms', text: '[LinkedIn, GitHub and email.]')],
  ),
  Section(
    id: SectionId.credits,
    title: 'Credits',
    entries: [Entry(title: '[Credits]', text: '[The works this site uses.]')],
  ),
];
