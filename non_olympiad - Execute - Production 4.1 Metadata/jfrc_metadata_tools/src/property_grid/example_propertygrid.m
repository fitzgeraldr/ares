% Demonstrates how to use the property pane.
%
% See also: PropertyGrid

% Copyright 2010 Levente Hunyadi
function example_propertygrid

properties = [ ...
    PropertyGridField('double', pi, ...
        'Category', 'Primitive types', ...
        'DisplayName', 'real double', ...
        'Description', 'Standard MatLab type.') ...
    PropertyGridField('single', pi, ...
        'Category', 'Primitive types', ...
        'DisplayName', 'real single', ...
        'Description', 'Single-precision floating point number.') ...
    PropertyGridField('integer', int32(23), ...
        'Category', 'Primitive types', ...
        'DisplayName', 'int32', ...
        'Description', 'A 32-bit integer value.') ...
    PropertyGridField('interval', int32(2), ...
        'Type', PropertyType('int32', 'scalar', [0 6]), ...
        'Category', 'Primitive types', ...
        'DisplayName', 'int32', ...
        'Description', 'A 32-bit integer value with an interval domain.') ...
    PropertyGridField('enumerated', int32(-1), ...
        'Type', PropertyType('int32', 'scalar', {int32(-1), int32(0), int32(1)}), ...
        'Category', 'Primitive types', ...
        'DisplayName', 'int32', ...
        'Description', 'A 32-bit integer value with an enumerated domain.') ...
    PropertyGridField('logical', true, ...
        'Category', 'Primitive types', ...
        'DisplayName', 'logical', ...
        'Description', 'A Boolean value that takes either true or false.') ...
    PropertyGridField('doublematrix', [], ...
        'Type', PropertyType('denserealdouble', 'matrix'), ...
        'Category', 'Compound types', ...
        'DisplayName', 'real double matrix', ...
        'Description', 'Matrix of standard MatLab type with empty initial value.') ...
    PropertyGridField('string', 'a sample string', ...
        'Category', 'Compound types', ...
        'DisplayName', 'string', ...
        'Description', 'A row vector of characters.') ...
    PropertyGridField('rowcellstr', {'a sample string','spanning multiple','lines'}, ...
        'Category', 'Compound types', ...
        'DisplayName', 'cell row of strings', ...
        'Description', 'A row cell array whose every element is a string (char array).') ...
    PropertyGridField('colcellstr', {'a sample string';'spanning multiple';'lines'}, ...
        'Category', 'Compound types', ...
        'DisplayName', 'cell column of strings', ...
        'Description', 'A column cell array whose every element is a string (char array).') ...
    PropertyGridField('season', 'spring', ...
        'Type', PropertyType('char', 'row', {'spring','summer','fall','winter'}), ...
        'Category', 'Compound types', ...
        'DisplayName', 'string', ...
        'Description', 'A row vector of characters that can take any of the predefined set of values.') ...
    PropertyGridField('set', [true false true], ...
        'Type', PropertyType('logical', 'row', {'A','B','C'}), ...
        'Category', 'Compound types', ...
        'DisplayName', 'set', ...
        'Description', 'A logical vector that serves an indicator of which elements from a universe are included in the set.') ...
    PropertyGridField('root', [], ...  % [] (and no type explicitly set) indicates that value is not editable
        'Category', 'Compound types', ...
        'DisplayName', 'root node') ...
    PropertyGridField('root.parent', int32(23), ...
        'Category', 'Compound types', ...
        'DisplayName', 'parent node') ...
    PropertyGridField('root.parent.child', int32(2007), ...
        'Category', 'Compound types', ...
        'DisplayName', 'child node') ...
];

% arrange flat list into a hierarchy based on qualified names
properties = properties.GetHierarchy();

% create figure
f = figure( ...
    'MenuBar', 'none', ...
    'Name', 'Property grid demo - Copyright 2010 Levente Hunyadi', ...
    'NumberTitle', 'off', ...
    'Toolbar', 'none');

% procedural usage
g = PropertyGrid(f, ...            % add property pane to figure
    'Properties', properties, ...  % set properties explicitly
    'Position', [0 0 0.5 1]);
h = PropertyGrid(f, ...
    'Position', [0.5 0 0.5 1]);

% declarative usage, bind object to grid
obj = SampleObject;  % a value object
h.Item = obj;        % bind object, discards any previously set properties

g.Item

% wait for figure to close
uiwait(f);

% display all properties and their values on screen
disp('Left-hand property grid');
disp(g.GetPropertyValues());
disp('Right-hand property grid');
disp(h.GetPropertyValues());
disp('SampleObject (modified)');
disp(h.Item);
disp('SampleNestedObject (modified)');
disp(h.Item.NestedObject);
