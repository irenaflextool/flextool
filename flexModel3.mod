# © International Renewable Energy Agency 2018-2021

#The FlexTool is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License
#as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

#The FlexTool is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

#You should have received a copy of the GNU Lesser General Public License along with the FlexTool.  
#If not, see <https://www.gnu.org/licenses/>.

#Author: Juha Kiviluoma (2017-2021), VTT Technical Research Centre of Finland

#########################
# Fundamental sets of the model
set entity 'e - contains both nodes and processes';
set process 'p - Particular activity that transfers, converts or stores commodities' within entity;
set node 'n - Any location where a balance needs to be maintained' within entity;
set nodeGroup 'ng - Any group of nodes that have a set of common constraints';
set commodity 'c - Stuff that is being processed';
set reserve 'r - Categories for the reservation of capacity_existing';
set time 't - Time steps in the data files'; 
set method 'm - Type of process that transfers, converts or stores commodities';
set debug 'flags to output debugging and test results';

#Individual methods
set method_1way_1variable;
set method_2way_1variable;
set method_2way_2variable;
set method_1way_offline;
set method_1way_online;
set method_2way_offline;
set method_2way_online;
set method_2way_online_exclusive;

#Method collections
set method_1variable;
set method_1way;
set method_2way;
set method_online;
set method_offline;
set method_sum_flow;
set method_sum_flow_2way;


set nodeBalance 'nodes that maintain a node balance' within node;
set nodeState 'nodes that have a state' within node;
set nodeInflow 'nodes that have an inflow' within node;
set nodeGroup_node 'member nodes of a particular nodeGroup' dimen 2 within {nodeGroup, node};
set process_method dimen 2 within {process, method};
set read_process_source_sink dimen 3 within {process, node, node};
set process_source := setof {(p, source, sink) in read_process_source_sink} (p, source);
set process_sink := setof {(p, source, sink) in read_process_source_sink} (p, sink);
set process_source_toProcess := {
    p in process, source in node, p2 in process 
	:  p = p2 
	&& (p, source) in process_source 
	&& (p2, source) in process_source 
	&& sum{(p, m) in process_method 
	         : m in method_sum_flow} 1};
set process_process_toSink := {
    p in process, p2 in process, sink in node 
	:  p = p2 
	&& (p, sink) in process_sink 
	&& (p2, sink) in process_sink 
	&& sum{(p, m) in process_method 
	        : m in method_sum_flow} 1};
set process_sink_toProcess := {
    sink in node, p in process, p2 in process 
	:  p = p2 
	&& (p, sink) in process_sink 
	&& (p2, sink) in process_sink 
	&& sum{(p, m) in process_method 
	         : m in method_sum_flow_2way} 1};
set process_process_toSource := {
    p in process, p2 in process, source in node 
	:  p = p2 
	&& (p, source) in process_source
	&& (p2, source) in process_source
	&& sum{(p, m) in process_method 
	        : m in method_sum_flow_2way} 1};
set process_source_toSink := {
    (p, source, sink) in read_process_source_sink 
	: sum{(p, m) in process_method 
	       : m in method_1variable union method_2way_2variable} 1};
set process_sink_toSource := {
    p in process, sink in node, source in node
	:  (p, source, sink) in read_process_source_sink
	&& sum{(p, m) in process_method 
	       : m in method_2way_2variable} 1};
set process_source_sink := 
    process_source_toSink union 
	process_sink_toSource union   
	process_source_toProcess union 
	process_process_toSink union 
	process_sink_toProcess union  # Add the 'wrong' direction in 2-way processes with multiple inputs/outputs
	process_process_toSource;     # Add the 'wrong' direction in 2-way processes with multiple inputs/outputs

set reserve_nodeGroup dimen 2;
set process_reserve_source_sink dimen 4;
set process_reserve_source dimen 3;
set process_reserve_sink dimen 3;
set commodity_node dimen 2; 

set commodityParam;
#set nodeParam;
set processParam;

set time_in_use := {t in time};
set peet := {(p, source, sink) in process_source_sink, t in time_in_use};
set preet := {(p, r, source, sink) in process_reserve_source_sink, t in time_in_use};
set pet_invest dimen 3 within {process, node, time_in_use};
set pet_divest dimen 3 within {process, node, time_in_use};
set nt_invest dimen 2 within {node, time_in_use};
set nt_divest dimen 2 within {node, time_in_use};

param p_commodity {(c, n) in commodity_node, commodityParam, t in time_in_use};
param p_process {process, processParam, time_in_use} default 0;
param p_process_source {(p, source) in process_source, processParam} default 0;
param p_process_sink {(p, sink) in process_sink, processParam} default 0;
param p_process_source_sink {(p, source, sink) in process_source_sink, processParam};
param p_pet_invest {(p, n, t) in pet_invest, processParam};
param p_inflow {n in nodeInflow, t in time_in_use};
param p_reserve {r in reserve, ng in nodeGroup, t in time_in_use};
param pq_up {n in nodeBalance};
param pq_down {n in nodeBalance};
param pq_reserve {(r, ng) in reserve_nodeGroup};
param t_jump{t in time};

param d_obj;
param d_flow {(p, source, sink, t) in peet} default 0;
param d_flow_1_or_2_variable {(p, source, sink, t) in peet} default 0;
param d_flowInvest {(p, n, t) in pet_invest} default 0;
param d_reserve {(p, r, source, sink, t) in preet} default 0;
param dq_reserve_up {(r, ng) in reserve_nodeGroup, t in time_in_use} default 0;

#########################
# Read parameter data (no time series yet)
table data IN 'CSV' 'entity.csv': entity <- [entity];
table data IN 'CSV' 'process.csv': process <- [process];
table data IN 'CSV' 'node.csv' : node <- [node];
table data IN 'CSV' 'nodeGroup.csv' : nodeGroup <- [nodeGroup];
table data IN 'CSV' 'commodity.csv' : commodity <- [commodity];
table data IN 'CSV' 'reserve.csv' : reserve <- [reserve];
table data IN 'CSV' 'time.csv' : time <- [time];

table data IN 'CSV' 'nodeBalance.csv' : nodeBalance <- [nodeBalance];
table data IN 'CSV' 'nodeState.csv' : nodeState <- [nodeState];
table data IN 'CSV' 'nodeInflow.csv' : nodeInflow <- [nodeInflow];
table data IN 'CSV' 'nodeGroup__node.csv': nodeGroup_node <- [nodeGroup,node];
table data IN 'CSV' 'process__method.csv' : process_method <- [process,method];
table data IN 'CSV' 'process__source.csv' : process_source <- [process,source];
table data IN 'CSV' 'process__sink.csv' : process_sink <- [process,sink];

table data IN 'CSV' '.csv' :  <- [];

table data IN 'CSV' 't_jump.csv' : [time], t_jump;

set nodeBalance 'nodes that maintain a node balance' within node;
set nodeState 'nodes that have a state' within node;
set nodeInflow 'nodes that have an inflow' within node;
set nodeGroup_node 'member nodes of a particular nodeGroup' dimen 2 within {nodeGroup, node};
set process_method dimen 2 within {process, method};
set read_process_source_sink dimen 3 within {process, node, node};
set process_source := setof {(p, source, sink) in read_process_source_sink} (p, source);
set process_sink := setof {(p, source, sink) in read_process_source_sink} (p, sink);


#########################
# Variable declarations
var v_flow {(p, source, sink, t) in peet};
var v_reserve {(p, r, source, sink, t) in preet} >= 0;
var v_state {n in nodeState, t in time_in_use} >= 0;
var v_online {p in process, t in time_in_use} >=0;
var v_flowInvest {(p, n, t) in pet_invest} >= 0;
var v_flowDivest {(p, n, t) in pet_divest} >= 0;
#var v_stateInvest {(n, t_invest) in nt_invest } >= 0;
var vq_state_up {n in nodeBalance, t in time_in_use} >= 0;
var vq_state_down {n in nodeBalance, t in time_in_use} >= 0;
var vq_reserve_up {(r, ng) in reserve_nodeGroup, t in time_in_use} >= 0;

#########################
## Data checks 
printf 'Checking: Data for 1 variable conversions directly from source to sink (and possibly back)\n';
check {(p, m) in process_method, t in time_in_use : m in method_1variable} p_process[p, 'efficiency', t] != 0 ;

printf 'Checking: Data for 1-way conversions with an online variable\n';
check {(p, m) in process_method, t in time_in_use : m in method_1way_online} p_process[p, 'efficiency', t] != 0;
for {(p, m) in process_method : m in method_1way_online} {
  check {(p, s) in process_source} p_process_source[p, s, 'coefficient'] > -1e15;
  check {(p, s) in process_sink} p_process_sink[p, s, 'coefficient'] > -1e15;
}

printf 'Checking: Data for 2-way linear conversions without online variables\n';
check {(p, m) in process_method, t in time_in_use : m in method_2way_offline} p_process[p, 'efficiency', t] != 0;
for {(p, m) in process_method : m in method_2way_offline} {
  check {(p, s) in process_source} p_process_source[p, s, 'coefficient'] > -1e15;
  check {(p, s) in process_sink} p_process_sink[p, s, 'coefficient'] > -1e15;
}


minimize total_cost: 
  + sum {(c, n) in commodity_node, t in time_in_use} p_commodity[c, n, 'price', t] 
      * ( 
	      + sum {(p, n, sink) in process_source_sink : sum{(p, m) in process_method : m in method_1variable union method_2way_2variable} 1 } v_flow[p, n, sink, t] / p_process[p, 'efficiency', t]
	      + sum {(p, n, sink) in process_source_sink : sum{(p, m) in process_method : m in method diff (method_1variable union method_2way_2variable)} 1 } v_flow[p, n, sink, t]
	      + sum {(p, source, n) in process_source_sink} v_flow[p, source, n, t]
		)
  + sum {n in nodeBalance, t in time_in_use} vq_state_up[n, t] * pq_up[n]
  + sum {n in nodeBalance, t in time_in_use} vq_state_down[n, t] * pq_down[n]
  + sum {(r, ng) in reserve_nodeGroup, t in time_in_use} vq_reserve_up[r, ng, t] * pq_reserve[r, ng]
  + sum {(p, n, t) in pet_invest} v_flowInvest[p, n, t] * p_pet_invest[p, n, t, 'invest_cost']
;
	  

# Energy balance in each node  
s.t. nodeBalance_eq {n in nodeBalance, t in time_in_use} :
  + (if n in nodeState then (v_state[n, t] -  v_state[n, t-1]))
  =
  + sum {(p, source, n) in process_source_sink} v_flow[p, source, n, t]
  + (if n in nodeInflow then p_inflow[n, t])
  + vq_state_up[n, t]
  - sum {(p, n, sink) in process_source_sink : sum{(p, m) in process_method : m in method_1variable union method_2way_2variable} 1 } (
       + v_flow[p, n, sink, t] / p_process[p, 'efficiency', t]
    )		
  - sum {(p, n, sink) in process_source_sink : sum{(p, m) in process_method : m in method diff (method_1variable union method_2way_2variable)} 1 } (
       + v_flow[p, n, sink, t]
    )		
  - vq_state_down[n, t]
;

s.t. reserveBalance_eq {r in reserve, ng in nodeGroup, t in time_in_use : (r, ng) in reserve_nodeGroup} :
  + sum {(p, r, source, n) in process_reserve_source_sink : (ng, n) in nodeGroup_node 
          && (r, ng) in reserve_nodeGroup} 
	   v_reserve[p, r, source, n, t]
  + p_reserve[r, ng, t]
  =
  + vq_reserve_up[r, ng, t]
  + sum {(p, r, n, sink) in process_reserve_source_sink : not (p, 'simple_1way') in process_method 
		  && (ng, n) in nodeGroup_node 
		  && (r, ng) in reserve_nodeGroup} 
	   v_reserve[p, r, n, sink, t]
  + sum {(p, r, n, sink) in process_reserve_source_sink :     (p, 'simple_1way') in process_method 
		  && (ng, n) in nodeGroup_node 
		  && (r, ng) in reserve_nodeGroup} 
	   v_reserve[p, r, n, sink, t] / p_process[sink, 'efficiency', t]
#  + vq_reserve_down[r, ng, t]
;

s.t. conversion_equality_constraint {(p, m) in process_method, t in time_in_use : m in method_sum_flow} :
  + sum {source in entity : (p, source) in process_source} 
    ( + v_flow[p, source, p, t] 
  	      * p_process_source[p, source, 'coefficient']
	)
	* p_process[p, 'efficiency', t]
  =
  + sum {sink in entity : (p, sink) in process_sink} 
    ( + v_flow[p, p, sink, t] 
	      * p_process_sink[p, sink, 'coefficient']
	)
;

s.t. maxToSink {(p, source, sink) in process_source_sink, t in time_in_use : (p, sink) in process_sink} :
  + v_flow[p, source, sink, t]
  + sum {r in reserve : (p, r, source, sink) in process_reserve_source_sink} v_reserve[p, r, source, sink, t]
  <=
  + p_process_sink[p, sink, 'capacity_existing']
  + sum {(p, sink, t_invest) in pet_invest : t_invest <= t} v_flowInvest[p, sink, t_invest]
  - sum {(p, sink, t_invest) in pet_divest : t_invest <= t} v_flowDivest[p, sink, t_invest]
;

s.t. minToSink {(p, source, sink) in process_source_sink, t in time_in_use : (p, sink) in process_sink && sum{(p,m) in process_method : m in method diff method_2way_1variable } 1 } :
  + v_flow[p, source, sink, t]
  >=
  + 0
;

display process_source_sink, process_method, process_source, process_sink;
# Special equations for the method with 2 variables presenting 2way connection between source and sink (without the process)
s.t. maxToSource {(p, source, sink) in process_source_sink, t in time_in_use : (p, source) in process_sink && sum{(p,m) in process_method : m in method_2way_2variable } 1 } :
  + v_flow[p, sink, source, t]
  + sum {r in reserve : (p, r, sink, source) in process_reserve_source_sink} v_reserve[p, r, sink, source, t]
  <=
  + p_process_sink[p, source, 'capacity_existing']
  + sum {(p, source, t_invest) in pet_invest : t_invest <= t} v_flowInvest[p, source, t_invest]
  - sum {(p, source, t_invest) in pet_divest : t_invest <= t} v_flowDivest[p, source, t_invest]
;

s.t. minToSource {(p, source, sink) in process_source_sink, t in time_in_use : (p, sink) in process_sink && sum{(p,m) in process_method : m in method_2way_2variable } 1 } :
  + v_flow[p, sink, source, t]
  >=
  + 0
;


solve;


param resultFile symbolic := "result.csv";

printf 'Upward slack for node balance\n' > resultFile;
for {n in nodeBalance, t in time_in_use}
  {
    printf '%s, %s, %.8g\n', n, t, vq_state_up[n, t].val >> resultFile;
  }

printf '\nDownward slack for node balance\n' >> resultFile;
for {n in nodeBalance, t in time_in_use}
  {
    printf '%s, %s, %.8g\n', n, t, vq_state_down[n, t].val >> resultFile;
  }

printf '\nReserve upward slack variable\n' >> resultFile;
for {r in reserve, ng in nodeGroup, t in time_in_use} 
  {
    printf '%s, %s, %s, %.8g\n', r, ng, t, vq_reserve_up[r, ng, t].val >> resultFile;
  }

printf '\nFlow variables\n' >> resultFile;
for {(p, source, sink) in process_source_sink, t in time_in_use}
  {
    printf '%s, %s, %s, %s, %.8g\n', p, source, sink, t, v_flow[p, source, sink, t].val >> resultFile;
  }

printf '\nFlow investments\n' >> resultFile;
for {(p, n, t_invest) in pet_invest} {
  printf '%s, %s, %s, %.8g\n', p, n, t_invest , v_flowInvest[p, n, t_invest].val >> resultFile;
}
  


printf '\nNode balance\n' >> resultFile;
for {n in node} {
  printf '\n%s\nNode', n >> resultFile;
  printf (if n in nodeInflow then ', %s' else ''), n >> resultFile;
  for {(p, source, n) in process_source_sink} {
    printf ', %s', source >> resultFile;
  }
  for {(p, n, sink) in process_source_sink : sum{(p, m) in process_method : m in method_1variable union method_2way_2variable} 1 } {
    printf ', %s', sink >> resultFile;
  }
  for {(p, n, sink) in process_source_sink : sum{(p, m) in process_method : m in method diff (method_1variable union method_2way_2variable)} 1 } {
    printf ', %s', sink >> resultFile;
  }
  printf '\n' >> resultFile;
  for {t in time_in_use} {
    printf '%s', t >> resultFile;
	printf (if n in nodeInflow then ', %.8g' else ''), p_inflow[n, t] >> resultFile; 
    for {(p, source, n) in process_source_sink} {
      printf ', %.8g', v_flow[p, source, n, t].val >> resultFile;
	}
    for {(p, n, sink) in process_source_sink : sum{(p, m) in process_method : m in method_1variable union method_2way_2variable} 1 } {
      printf ', %.8g', -v_flow[p, n, sink, t].val / p_process[p, 'efficiency', t] >> resultFile;
	}
    for {(p, n, sink) in process_source_sink : sum{(p, m) in process_method : m in method diff (method_1variable union method_2way_2variable)} 1 } {
      printf ', %.8g', -v_flow[p, n, sink, t].val >> resultFile;
	}
    printf '\n' >> resultFile;
  }
}


### UNIT TESTS ###
param unitTestFile symbolic := "tests/unitTests.txt";
printf (if sum{d in debug} 1 then '%s --- ' else ''), time2str(gmtime(), "%FT%TZ") >> unitTestFile;
for {d in debug} {
  printf '%s  ', d >> unitTestFile;
}
printf (if sum{d in debug} 1 then '\n\n' else '') >> unitTestFile;

## Objective test
printf (if (sum{d in debug} 1 && total_cost.val <> d_obj) 
        then 'Objective value test fails. Model value: %.8g, test value: %.8g\n' else ''), total_cost.val, d_obj >> unitTestFile;

## Testing flows from and to node
for {n in node : 'method_1way_1variable' in debug || 'mini_system' in debug} {
  printf 'Testing incoming flows of node %s\n', n >> unitTestFile;
  for {(p, source, n, t) in peet} {
    printf (if v_flow[p, source, n, t].val <> d_flow[p, source, n, t] 
	        then 'Test fails at %s, %s, %s, %s, model value: %.8g, test value: %.8g\n' else ''),
			    p, source, n, t, v_flow[p, source, n, t].val, d_flow[p, source, n, t] >> unitTestFile;
  }
  printf 'Testing outgoing flows of node %s\n', n >> unitTestFile;
  for {(p, n, sink, t) in peet : sum{(p, m) in process_method : m in method_1variable union method_2way_2variable} 1 } {
    printf (if -v_flow[p, n, sink, t].val / p_process[p, 'efficiency', t] <> d_flow_1_or_2_variable[p, n, sink, t] 
	        then 'Test fails at %s, %s, %s, %s, model value: %.8g, test value: %.8g\n' else ''),
	            p, n, sink, t, -v_flow[p, n, sink, t].val / p_process[p, 'efficiency', t], d_flow_1_or_2_variable[p, n, sink, t] >> unitTestFile;
  }
  for {(p, n, sink, t) in peet : sum{(p, m) in process_method : m in method diff (method_1variable union method_2way_2variable)} 1 } {
    printf (if -v_flow[p, n, sink, t].val <> d_flow[p, n, sink, t] 
	        then 'Test fails at %s, %s, %s, %s, model value: %.8g, test value: %.8g\n' else ''),
	            p, n, sink, t, -v_flow[p, n, sink, t].val, d_flow[p, n, sink, t] >> unitTestFile;
  }
  printf '\n' >> unitTestFile;
}  

display reserve_nodeGroup;
## Testing reserves
for {(p, r, source, sink, t) in preet} {
  printf (if v_reserve[p, r, source, sink, t].val <> d_reserve[p, r, source, sink, t]
          then 'Reserve test fails at %s, %s, %s, %s, %s. Model value: %.8g, test value: %.8g\n' else ''),
		      p, r, source, sink, t, v_reserve[p, r, source, sink, t].val, d_reserve[p, r, source, sink, t] >> unitTestFile;
}
for {(r, ng) in reserve_nodeGroup, t in time_in_use} {
  printf (if vq_reserve_up[r, ng, t].val <> dq_reserve_up[r, ng, t]
          then 'Reserve slack variable test fails at %s, %s, %s. Model value: %.8g, test value: %.8g\n' else ''),
		      r, ng, t, vq_reserve_up[r, ng, t].val, dq_reserve_up[r, ng, t] >> unitTestFile;
}

## Testing investments
for {(p, n, t_invest) in pet_invest : 'invest_source_to_sink' in debug} {
  printf 'Testing investment decisions of %s %s %s\n', p, n, t_invest >> unitTestFile;
  printf (if v_flowInvest[p, n, t_invest].val <> d_flowInvest[p, n, t_invest]
          then 'Test fails at %s, %s, %s, model value: %.8g, test value: %.8g\n' else ''),
		      p, n, t_invest, v_flowInvest[p, n, t_invest].val, d_flowInvest[p, n, t_invest] >> unitTestFile;
}
printf (if sum{d in debug} 1 then '\n\n' else '') >> unitTestFile;	  


end;
