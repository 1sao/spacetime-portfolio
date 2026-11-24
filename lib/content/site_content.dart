import 'content.dart';

const List<Section> sections = [
  Section(id: SectionId.about, title: 'About', descriptor: '[Who I am]'),
  Section(
    id: SectionId.work,
    title: 'Work',
    descriptor: '13 tenants · 1M+ downloads',
  ),
  Section(
    id: SectionId.personal,
    title: 'Personal',
    descriptor: '[Side projects]',
  ),
  Section(
    id: SectionId.contact,
    title: 'CV & Contact',
    descriptor: '[CV, LinkedIn, GitHub, email]',
  ),
  Section(id: SectionId.credits, title: 'Credits'),
];

const List<Credit> credits = [
  Credit(
    workName: 'Star Nest',
    author:
        'Pablo Román Andrioli (Kali), with a noise clamp by Beibei Wang '
        'and Huw Bowles',
    licenceName: 'MIT',
    licenceFile: 'star-nest.txt',
  ),
  Credit(
    workName: 'Black Hole',
    author: 'nethe550',
    licenceName: 'MIT',
    licenceFile: 'black-hole.txt',
  ),
  Credit(
    workName: 'Planet Shader',
    author: 'mrange',
    licenceName: 'CC0',
    licenceFile: 'planet-shader.txt',
  ),
  Credit(
    workName: 'Kepler 256o',
    author: 'otaviogood',
    licenceName: 'CC0',
    licenceFile: 'kepler-256o.txt',
  ),
  Credit(
    workName: 'Hash without Sine',
    author: 'Dave Hoskins',
    licenceName: 'MIT',
    licenceFile: 'hash-without-sine.txt',
  ),
  Credit(
    workName: 'webgl-noise',
    author: 'Ian McEwan (Ashima Arts)',
    licenceName: 'MIT',
    licenceFile: 'webgl-noise.txt',
  ),
  Credit(
    workName: 'Saira',
    author: 'the Saira Project Authors (Omnibus-Type)',
    licenceName: 'SIL Open Font License 1.1',
    licenceFile: 'saira.txt',
  ),
  Credit(
    workName: 'Atkinson Hyperlegible Next',
    author: 'the Atkinson Hyperlegible Next Project Authors',
    licenceName: 'SIL Open Font License 1.1',
    licenceFile: 'atkinson-hyperlegible-next.txt',
  ),
];
