import 'content.dart';

/// Everything the site says. Copy in brackets is placeholder.
const List<Category> categories = [
  Category(
    slug: 'projects',
    name: 'Projects',
    messages: [
      Message(
        slug: 'project-01',
        title: '[Project 01]',
        text: '[What it is, your part, one result.]',
      ),
      Message(
        slug: 'project-02',
        title: '[Project 02]',
        text: '[What it is, your part, one result.]',
      ),
      Message(
        slug: 'project-03',
        title: '[Project 03]',
        text: '[What it is, your part, one result.]',
      ),
    ],
  ),
  Category(
    slug: 'experience',
    name: 'Experience',
    messages: [
      Message(
        slug: 'flight-log',
        title: 'Flight log',
        text: '[Your roles and years, as a short timeline.]',
      ),
    ],
  ),
  Category(
    slug: 'contact',
    name: 'Contact',
    messages: [
      Message(
        slug: 'comms',
        title: 'Comms',
        text: '[LinkedIn, GitHub and email.]',
      ),
    ],
  ),
  Category(
    slug: 'category-04',
    name: '[Category]',
    messages: [
      Message(
        slug: 'message-01',
        title: '[Message 01]',
        text: '[Placeholder copy.]',
      ),
      Message(
        slug: 'message-02',
        title: '[Message 02]',
        text: '[Placeholder copy.]',
      ),
    ],
  ),
];
