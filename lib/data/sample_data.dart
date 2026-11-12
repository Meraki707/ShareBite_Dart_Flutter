import 'package:flutter/material.dart';

import '../models/sharebite_models.dart';

const listingCategories = [
  'Tudo',
  'Frutas',
  'Vegetais',
  'Hortaliças',
  'Pães e massas',
  'Grãos e cereais',
  'Laticínios',
  'Conservas e geleias',
];
const listingModes = ['Doação', 'Troca', 'Venda'];

String samplePhoto(String id) =>
    'https://images.unsplash.com/$id?auto=format&fit=crop&w=900&q=84';

List<Listing> sampleListings() => [
      Listing(
        id: 'cesta',
        title: 'Cesta da horta de hoje',
        category: 'Hortaliças',
        mode: 'Doação',
        place: 'Pinheiros, São Paulo',
        distance: '800 m',
        price: 'Grátis',
        owner: 'Horta da Vila',
        description:
            'Legumes e folhas frescos, colhidos hoje. Retirada até o fim da tarde.',
        image: samplePhoto('photo-1542838132-92c53300491e'),
      ),
      Listing(
        id: 'pao',
        title: 'Pães artesanais fresquinhos',
        category: 'Pães e massas',
        mode: 'Troca',
        place: 'Vila Madalena, São Paulo',
        distance: '1,4 km',
        price: 'Por troca',
        owner: 'Pão do Bairro',
        description:
            'Pães de fermentação natural que saíram do forno esta manhã. Aceitamos geleia ou frutas.',
        image: samplePhoto('photo-1509440159596-0249088772ff'),
        acceptedCategories: ['Frutas', 'Conservas e geleias'],
      ),
      Listing(
        id: 'maca',
        title: 'Maçãs orgânicas da semana',
        category: 'Frutas',
        mode: 'Venda',
        place: 'Sumarezinho, São Paulo',
        distance: '2,1 km',
        price: 'R\$ 8',
        owner: 'Sítio das Frutas',
        description:
            'Maçãs orgânicas maduras, perfeitas para comer ou fazer uma torta.',
        image: samplePhoto('photo-1560806887-1e4cd0b6cbd6'),
      ),
      Listing(
        id: 'tomates',
        title: 'Tomates maduros do quintal',
        category: 'Vegetais',
        mode: 'Doação',
        place: 'Jardins, São Paulo',
        distance: '2,7 km',
        price: 'Grátis',
        owner: 'Ana Ribeiro',
        description:
            'Tomates fresquinhos colhidos no quintal, prontos para saladas e molhos.',
        image: samplePhoto('photo-1546094096-0df4bcaaa337'),
      ),
      Listing(
        id: 'bananas',
        title: 'Bananas nanicas da feira',
        category: 'Frutas',
        mode: 'Troca',
        place: 'Sumarezinho, São Paulo',
        distance: '3,2 km',
        price: 'Por troca',
        owner: 'Marina Costa',
        description:
            'Bananas maduras e docinhas, ótimas para comer ou preparar um bolo.',
        image: samplePhoto('photo-1571771894821-ce9b6c11b08e'),
        acceptedCategories: ['Hortaliças', 'Pães e massas'],
      ),
      Listing(
        id: 'espinafre',
        title: 'Espinafre fresquinho',
        category: 'Hortaliças',
        mode: 'Doação',
        place: 'Vila Madalena, São Paulo',
        distance: '3,5 km',
        price: 'Grátis',
        owner: 'Quintal da Lú',
        description:
            'Folhas de espinafre recém-colhidas, boas para saladas e refogados.',
        image: samplePhoto('photo-1576045057995-568f588f82fb'),
      ),
    ];

List<Conversation> sampleConversations() => [
      Conversation(
        id: 'horta',
        name: 'Horta da Vila',
        note: 'Horta comunitária · Pinheiros',
        listing: 'Cesta da horta de hoje',
        image: samplePhoto('photo-1542838132-92c53300491e'),
        icon: Icons.spa_outlined,
        time: '10:42',
        messages: [
          ChatMessage(
            'Oi! Vi a cesta de hoje. Ainda está disponível?',
            true,
            '10:35',
          ),
          ChatMessage(
            'Oi! Sim, consigo deixar separada até às 18h.',
            false,
            '10:42',
          ),
        ],
      ),
      Conversation(
        id: 'pao-chat',
        name: 'Pão do Bairro',
        note: 'Comércio parceiro · Vila Madalena',
        listing: 'Pães artesanais fresquinhos',
        image: samplePhoto('photo-1509440159596-0249088772ff'),
        icon: Icons.storefront_outlined,
        time: 'Ontem',
        messages: [
          ChatMessage('Pode ser uma troca por geleia?', false, 'Ontem')
        ],
      ),
      Conversation(
        id: 'ana',
        name: 'Ana Ribeiro',
        note: 'Vizinha · Jardins',
        listing: 'Tomates maduros do quintal',
        image: samplePhoto('photo-1546094096-0df4bcaaa337'),
        time: 'Seg',
        messages: [
          ChatMessage('Combinado, te espero na portaria.', false, 'Seg'),
        ],
      ),
    ];
