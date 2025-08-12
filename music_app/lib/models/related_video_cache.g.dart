// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'related_video_cache.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRelatedVideoCacheCollection on Isar {
  IsarCollection<RelatedVideoCache> get relatedVideoCaches => this.collection();
}

const RelatedVideoCacheSchema = CollectionSchema(
  name: r'RelatedVideoCache',
  id: -1523112242943633774,
  properties: {
    r'cachedAt': PropertySchema(
      id: 0,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'relatedVideosJson': PropertySchema(
      id: 1,
      name: r'relatedVideosJson',
      type: IsarType.string,
    ),
    r'userId': PropertySchema(
      id: 2,
      name: r'userId',
      type: IsarType.string,
    ),
    r'videoId': PropertySchema(
      id: 3,
      name: r'videoId',
      type: IsarType.string,
    )
  },
  estimateSize: _relatedVideoCacheEstimateSize,
  serialize: _relatedVideoCacheSerialize,
  deserialize: _relatedVideoCacheDeserialize,
  deserializeProp: _relatedVideoCacheDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _relatedVideoCacheGetId,
  getLinks: _relatedVideoCacheGetLinks,
  attach: _relatedVideoCacheAttach,
  version: '3.1.0+1',
);

int _relatedVideoCacheEstimateSize(
  RelatedVideoCache object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.relatedVideosJson.length * 3;
  bytesCount += 3 + object.userId.length * 3;
  bytesCount += 3 + object.videoId.length * 3;
  return bytesCount;
}

void _relatedVideoCacheSerialize(
  RelatedVideoCache object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeString(offsets[1], object.relatedVideosJson);
  writer.writeString(offsets[2], object.userId);
  writer.writeString(offsets[3], object.videoId);
}

RelatedVideoCache _relatedVideoCacheDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RelatedVideoCache();
  object.cachedAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.relatedVideosJson = reader.readString(offsets[1]);
  object.userId = reader.readString(offsets[2]);
  object.videoId = reader.readString(offsets[3]);
  return object;
}

P _relatedVideoCacheDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _relatedVideoCacheGetId(RelatedVideoCache object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _relatedVideoCacheGetLinks(
    RelatedVideoCache object) {
  return [];
}

void _relatedVideoCacheAttach(
    IsarCollection<dynamic> col, Id id, RelatedVideoCache object) {
  object.id = id;
}

extension RelatedVideoCacheQueryWhereSort
    on QueryBuilder<RelatedVideoCache, RelatedVideoCache, QWhere> {
  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RelatedVideoCacheQueryWhere
    on QueryBuilder<RelatedVideoCache, RelatedVideoCache, QWhereClause> {
  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension RelatedVideoCacheQueryFilter
    on QueryBuilder<RelatedVideoCache, RelatedVideoCache, QFilterCondition> {
  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      cachedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      cachedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      cachedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cachedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      relatedVideosJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relatedVideosJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      relatedVideosJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'relatedVideosJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      relatedVideosJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'relatedVideosJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      relatedVideosJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'relatedVideosJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      relatedVideosJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'relatedVideosJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      relatedVideosJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'relatedVideosJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      relatedVideosJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'relatedVideosJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      relatedVideosJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'relatedVideosJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      relatedVideosJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relatedVideosJson',
        value: '',
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      relatedVideosJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'relatedVideosJson',
        value: '',
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      userIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      videoIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'videoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      videoIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'videoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      videoIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'videoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      videoIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'videoId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      videoIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'videoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      videoIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'videoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      videoIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'videoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      videoIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'videoId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      videoIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'videoId',
        value: '',
      ));
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterFilterCondition>
      videoIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'videoId',
        value: '',
      ));
    });
  }
}

extension RelatedVideoCacheQueryObject
    on QueryBuilder<RelatedVideoCache, RelatedVideoCache, QFilterCondition> {}

extension RelatedVideoCacheQueryLinks
    on QueryBuilder<RelatedVideoCache, RelatedVideoCache, QFilterCondition> {}

extension RelatedVideoCacheQuerySortBy
    on QueryBuilder<RelatedVideoCache, RelatedVideoCache, QSortBy> {
  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy>
      sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy>
      sortByRelatedVideosJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedVideosJson', Sort.asc);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy>
      sortByRelatedVideosJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedVideosJson', Sort.desc);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy>
      sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy>
      sortByVideoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoId', Sort.asc);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy>
      sortByVideoIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoId', Sort.desc);
    });
  }
}

extension RelatedVideoCacheQuerySortThenBy
    on QueryBuilder<RelatedVideoCache, RelatedVideoCache, QSortThenBy> {
  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy>
      thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy>
      thenByRelatedVideosJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedVideosJson', Sort.asc);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy>
      thenByRelatedVideosJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedVideosJson', Sort.desc);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy>
      thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy>
      thenByVideoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoId', Sort.asc);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QAfterSortBy>
      thenByVideoIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoId', Sort.desc);
    });
  }
}

extension RelatedVideoCacheQueryWhereDistinct
    on QueryBuilder<RelatedVideoCache, RelatedVideoCache, QDistinct> {
  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QDistinct>
      distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QDistinct>
      distinctByRelatedVideosJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'relatedVideosJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QDistinct>
      distinctByUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RelatedVideoCache, RelatedVideoCache, QDistinct>
      distinctByVideoId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'videoId', caseSensitive: caseSensitive);
    });
  }
}

extension RelatedVideoCacheQueryProperty
    on QueryBuilder<RelatedVideoCache, RelatedVideoCache, QQueryProperty> {
  QueryBuilder<RelatedVideoCache, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RelatedVideoCache, DateTime, QQueryOperations>
      cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<RelatedVideoCache, String, QQueryOperations>
      relatedVideosJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relatedVideosJson');
    });
  }

  QueryBuilder<RelatedVideoCache, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }

  QueryBuilder<RelatedVideoCache, String, QQueryOperations> videoIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'videoId');
    });
  }
}
