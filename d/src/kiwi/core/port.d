module kiwi.core.port;

import kiwi.core.node;
import kiwi.core.nodeinfo;
import kiwi.core.runtimetype;
import kiwi.core.commons;

import kiwi.utils.array;

struct InputPort
{
    package void initialize(Node* n, ubyte i)
    {
        _node = n;
        _index = i;
    }

    bool isConnectedTo( ref const(OutputPort) input ) const
    {
        return _connection is &input;
    }

    bool isCompatible( ref OutputPort port ) const
    {
        return dataType == port.dataType;
    }
    
    bool connect( ref OutputPort port )
    {
        return connectPorts(port, this);
    }

    void disconnect()
    {
        if ( !isConnected )
            return;
        disconnectPorts(*_connection, this);
        assert( !isConnected );
    }

    void disconnectAll()
    {
        disconnect();
    }

    @property
    {
        inout(OutputPort)* connection() inout pure
        {
            return _connection; 
        }

        bool isConnected() const pure
        {
            return _connection !is null;
        }

        inout(Node)* node() inout pure
        {
            return _node;
        }
        
        ref inout(RuntimeType) data() inout pure
        {
            if( isConnected )
                return connection.data;
            assert(false);
        }
        
        ref const(T) dataAs(T)()
        {
            if( isConnected )
                return _connection.dataAs!T;
            assert(false, "InputPort.dataAs!T invoked while the port is not connected.");
        }

        auto info() const pure
        {
            return &node.info.inputs[index];
        }

        ubyte index() const pure
        {
            return _index;
        }

        DataTypeID dataType() const pure
        {
            return info.dataType;
        }

        auto name() const pure
        {
            return info.name;
        }

        auto flags() const pure
        {
            return info.flags;
        }

        bool isOptionnal() const pure
        {
            return (flags & OPT)!=0;
        }
    }
    
private:
    OutputPort* _connection;
    Node*       _node;
    ubyte       _index;
}




struct OutputPort
{
    package void initialize(Node* n, ubyte i)
    {
        _node = n;
        _index = i;
        if (n !is null)
            _data.type = info.dataType;

    }

    bool isConnectedTo( ref const(InputPort) input ) const pure
    {
        foreach( c ; _connections )
            if ( c is &input )
                return true;
        return false;
    }

    bool isCompatible( ref InputPort port ) const pure
    {
        return dataType is port.dataType;
    }

    bool connect( ref InputPort port )
    {
        return connectPorts(this, port);
    }

    void disconnect( ref InputPort port )
    {
        disconnectPorts( this, port );
    }

    void disconnectAll()
    {
        while( connections.length > 0 )
            disconnectPorts(this, *_connections[$-1]);
        assert( !isConnected );
    }

    void setData(T)(T value)
    {
        _data = value;
    }

    @property
    {
        inout(Node)* node() inout pure
        {
            return _node;
        }

        auto info() const pure
        {
            return &node.info.outputs[index];
        }
        
        ref inout(RuntimeType) data() inout pure
        {
            return _data;
        }
        
        ref T dataAs(T)()
        {
            return _data.get!T();
        }

        auto connections() inout pure
        {
            return _connections[0..$];
        }

        bool isConnected() const pure
        {
            return _connections.length > 0;
        }

        ubyte index() const pure
        {
            return _index;
        }

        DataTypeID dataType() const pure
        {
            return info.dataType;
        }

        auto name() const pure
        {
            return info.name;
        }

        auto flags() const pure
        {
            return info.flags;
        }

        bool isOptionnal() const
        {
            return (flags & OPT) != 0;
        }
    }
    
private:
    Node*           _node;
    ubyte           _index;
    InputPort*[]    _connections;
    RuntimeType     _data;
}

private size_t findInArray(T)(ref T[] arr, const T elt)
{
    foreach( i, e ; arr )
        if ( e == elt )
            return i;
    
    return arr.length;
}

private bool connectPorts(ref OutputPort output, ref InputPort input )
{
    if ( !input.isCompatible( output ) )
		return false;

	if ( input.isConnected ) input.disconnectAll();

	input._connection = &output;
	output._connections ~= &input;
    
    // previous nodes cache
    if( !contains(input.node._previousNodes, output.node) )
        input.node._previousNodes ~= output.node;
    // next nodes cache
    if( !contains(output.node._nextNodes, input.node) )
        output.node._nextNodes ~= input.node;

	return true;
}

private void disconnectPorts( ref OutputPort output, ref InputPort input)
{
    auto lb = log.scoped("disconnectPorts");
    if ( !input.isConnectedTo(output) ) return;

	int i2 = findInArray!(InputPort*)(output._connections, &input);

    if ( i2 != output._connections.length ){
        assert( output._connections[i2].node() == input.node() );
    }
	// proceed with the disconnection
	input._connection = null;
	output._connections[i2] = output._connections[$ -1];
	output._connections.length = output._connections.length -1;

    auto inputNode = input.node;
    auto outputNode = output.node;
    
    if (inputNode)
    {
        bool found = false;
        foreach ( p ; inputNode.inputs )
        {
            if (p.connection && (p.connection.node is outputNode))
            {
                found = true;
                break;
            }
        }
        if (!found)
        {
            int idx = kiwi.utils.array.indexOf(inputNode._previousNodes, outputNode);
            assert(idx >= 0, "bug: The previous nodes cache should contain the node."); 
            kiwi.utils.array.quickRemove(inputNode._previousNodes, idx);
        }
    }
    if (outputNode)
    {
        bool found = false;
        foreach ( p ; outputNode.outputs )
            foreach ( c ; p.connections )
            {
                if (c.node == inputNode)
                {
                    found = true;
                    break;
                }
            }
        if (!found)
        {
            int idx = kiwi.utils.array.indexOf(outputNode._nextNodes, inputNode);
            assert(idx >= 0, "bug: The next nodes cache should contain the node."); 
            kiwi.utils.array.quickRemove(outputNode._nextNodes, idx);
        }
    }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//                                  TESTS
//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

unittest
{
    import kiwi.core.nodeinfo;
    import kiwi.utils.testing;
    import kiwi.utils.hstring;
    
    import std.conv;
    
    auto unit = TestSuite("kiwi.core.ports");

    class Foo {};
    class Bar {};

    DataTypeID fooID = Foo.classinfo;
    DataTypeID barID = Bar.classinfo;
    assert( fooID != barID );

    NodeTypeInfo ntinfo1 = {
        inputs : [
            { StrHash("in#1"), fooID, READ },
            { StrHash("in#2"), barID, READ|OPT }
        ],
        outputs : [
            { StrHash("out"), fooID, READ|OPT },
        ]
    };

    NodeTypeInfo ntinfo2 = {
        inputs : [
            { StrHash("in#1"), fooID, READ },
            { StrHash("in#2"), fooID, READ|OPT }
        ],
        outputs : [
            { StrHash("out"), barID, READ|OPT },
        ]
    };

    Node n1, n2;
    n1.initialize( null, &ntinfo1 );
    n2.initialize( null, &ntinfo2 );

    unit.test( n1.inputs[0].name == StrHash("in#1"), "Input port name (0)." );
    unit.test( n1.inputs[1].name == StrHash("in#2"), "Input port name (1)." );
    unit.test( n1.outputs[0].name == StrHash("out"), "Output port name." );

    for( int i = 0; i < n1.inputs.length; ++i )
        unit.test( n1.inputs[i].index == i, "Input port index "~to!string(i) );
    for( int i = 0; i < n1.outputs.length; ++i )
        unit.test( n1.outputs[i].index == i, "Output port index "~to!string(i) );

    unit.test( n1.inputs[0].dataType == fooID, "Input data type (0)." );
    unit.test( n1.inputs[1].dataType == barID, "Input data type (1)." );
    unit.test( n1.outputs[0].dataType == fooID, "Input data type (1)." );
    unit.test( !n2.inputs[0].isOptionnal, "Non optionnal port" );
    unit.test( n2.inputs[1].isOptionnal, "Optionnal port" );

    unit.test( n1.nextNodes.length == 0, "n1 not connected therefore can't have next nodes" );
    unit.test( n1.previousNodes.length == 0, "n1 not connected therefore can't have previous nodes" );

    // trying to disconnect while not connected
    // should not crash
    n1.input().disconnect();
    n1.output().disconnectAll();
    n1.output().disconnect( n2.input() );

    unit.test( n1.output(0).isCompatible( n2.input(0) ) );
    
    auto status1 = n2.output().connect( n1.input(1) );
    unit.test( status1, "Connecting compatible ports" );
    unit.test( n2.outputs[0].isConnected, "Output connection state." );
    unit.test( n1.inputs[1].isConnected, "Input connection state." );
    
    unit.test( n1.nextNodes == [] );
    unit.test( n1.previousNodes == [&n2] );
    unit.test( n2.nextNodes == [&n1] );
    unit.test( n2.previousNodes == [] );

    n1.input(1).disconnect();
    unit.test( !n1.input(1).isConnected, "Input connection state." );
    unit.test( !n2.output().isConnected, "Output connection state." );
    
    unit.test( n1.nextNodes == [] );
    unit.test( n1.previousNodes == [] );
    unit.test( n2.nextNodes == [] );
    unit.test( n2.previousNodes == [] );
    
    auto status2 = n1.inputs[1].connect( n2.outputs[0] );
    unit.test( status2, "Connecting compatible ports" );
    unit.test( n2.outputs[0].isConnectedTo(n1.inputs[1]), "Output connection state." );
    unit.test( n1.inputs[1].isConnectedTo(n2.outputs[0]), "Input connection state." );
    
    unit.test( n1.nextNodes == [] );
    unit.test( n1.previousNodes == [&n2] );
    unit.test( n2.nextNodes == [&n1] );
    unit.test( n2.previousNodes == [] );
    
    n2.output(0).disconnect( n1.input(1) );
    unit.test( !n1.input(1).isConnected, "Input connection state." );
    unit.test( !n2.output().isConnected, "Output connection state." );
    
    unit.test( n1.nextNodes == [] );
    unit.test( n1.previousNodes == [] );
    unit.test( n2.nextNodes == [] );
    unit.test( n2.previousNodes == [] );
    
    auto status3 = n2.output().connect( n1.input(1) );
    auto status3bis = n2.output().connect( n1.input(1) );
    unit.test( n2.output().connections.length == 1, "Connecting twice: nb of connections." );
    
    unit.test( n1.nextNodes == [] );
    unit.test( n1.previousNodes == [&n2] );
    unit.test( n2.nextNodes == [&n1] );
    unit.test( n2.previousNodes == [] );
    
    n2.output().disconnectAll();
    assert( !n1.input().isConnected );
    assert( !n2.output().isConnected );
    
    unit.test( n1.nextNodes == [] );
    unit.test( n1.previousNodes == [] );
    unit.test( n2.nextNodes == [] );
    unit.test( n2.previousNodes == [] );
    
    unit.test( ! n2.output().isCompatible( n1.input() ), "Uncompatible port check" );
    auto status4 = n2.output().connect( n1.input() );
    unit.test( !n1.input().isConnected, "Input should not be connected." );
    unit.test( !n2.output().isConnected, "Output should not be connected." );
    
    unit.test( n1.nextNodes == [] );
    unit.test( n1.previousNodes == [] );
    unit.test( n2.nextNodes == [] );
    unit.test( n2.previousNodes == [] );
    
}
