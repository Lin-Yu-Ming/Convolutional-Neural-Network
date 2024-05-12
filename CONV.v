`timescale 1ns/10ps

module  CONV(
	input				clk,
	input				reset,
	output logic		busy,	
	input				ready,	

	output logic [13:0]	iaddr,
	input  		 [7:0]	idata,	
	output logic		ioe,

	output logic		wen_L0,
	output logic		oe_L0,
	output logic [13:0]	addr_L0,
	output logic [11:0] w_data_L0,
	input  		 [11:0] r_data_L0,

	output logic 		wen_L1,
	output logic		oe_L1,
	output logic [11:0]	addr_L1,
	output logic [11:0]	w_data_L1,
	input  		 [11:0]	r_data_L1,

	output logic		oe_weight,
	output logic [15:0]	addr_weight,
	input  logic signed  [7:0]  r_data_weight,

	output logic		wen_L2,
	output logic [3:0]	addr_L2,
	output logic [31:0]	w_data_L2
	);


reg [1:0] fully_flag;
reg[3:0] i0,i4,i5,i6;
reg [3:0] state,next_state;
reg [11:0] data [0:8];
reg [15:0] zero_index,addr_index0,addr_index1,addr_index2,addr_index3,addr_index4,L0_index;
reg signed [31:0] data_fully;
parameter INIT=4'd0,ADDR1=4'd1,WAIT1=4'd2,DATA_i0=4'd3,LAYER0=4'd4,ADDR2=4'd5,LAYER1=4'd6,
		  LAYER1_1=4'd7,ADDR3=4'd8,WAIT3=4'd9,LAYER2=4'd10,LAYER2_1=4'd11,FINI=4'd12;

always @(posedge clk or posedge reset ) begin
  if(reset) state<=INIT;
  else state<=next_state;
end

always @(*) begin
	case (state)
		INIT:begin
			next_state=(ready)?ADDR1:INIT;	
		end 

		ADDR1:begin
			next_state=WAIT1;
		end

		WAIT1:begin
			next_state=(fully_flag==0)?DATA_i0:(fully_flag==1)?LAYER1:LAYER2;		   
		end

		DATA_i0:begin
			next_state=(i0>=8&&zero_index==0||i0>=7&&zero_index==127||i0>=5&&zero_index==16510||
			            i0>=4&&zero_index==16637||i0>=8&&zero_index%130==0&&zero_index!=0&&zero_index!=16510||
						i5>=7&&zero_index%130==127&&zero_index!=127&&zero_index!=16637||
						i6>=8&&zero_index>0&&zero_index<127||i4>=5&&zero_index>16510&&zero_index<16637||i4>=8)?LAYER0:ADDR1;	
		end

		LAYER0:begin
			next_state=(L0_index>=16383)?ADDR2:ADDR1;
		end
        
		ADDR2:begin
			next_state=WAIT1;
		end

		LAYER1:begin
			next_state=(i0>=3)?LAYER1_1:ADDR2;
		end

		LAYER1_1:begin
			next_state=(addr_index1>=4095)?ADDR3:ADDR2;
		end

		ADDR3:begin
			next_state=WAIT1;
		end

		LAYER2:begin
			next_state=(addr_index2>=4095)?LAYER2_1:ADDR3;
		end

		LAYER2_1:begin
			next_state=(addr_index4>=9)?FINI:ADDR3;
		end
    
		FINI:begin
			next_state=INIT;
		end

		default; 
	endcase
	
end

always @(posedge clk) begin
	case (state)
		INIT:begin
			zero_index<=16'h0;
			i0<=4'h4;
			i4<=4'h0;
			i5<=4'h0;
			i6<=4'h3;
			addr_index0<=0;
			addr_index1<=126;
			addr_index2<=0;
			addr_index3<=16128;
			addr_index4<=0;
			L0_index<=0;
			wen_L0<=0;
			ioe<=0;
			busy<=0;
			data_fully<=0;
			fully_flag<=0;
		end 

		ADDR1:begin
			wen_L0<=0;
            ioe<=1;
			if (zero_index==0) begin
				if (i0==4) iaddr<=14'h0;
				else if (i0==5) iaddr<=14'h1; 
				else if (i0==7) iaddr<=14'h80;
				else iaddr<=14'h81;	
			end

			else if (zero_index==127) begin
				if (i0==3) iaddr<=14'h7E;
				else if (i0==4) iaddr<=14'h7F; 
				else if (i0==6) iaddr<=14'hFE;
				else iaddr<=14'hFF;	
			end

			else if (zero_index==16510) begin
				if (i0==1) iaddr<=14'h3F00;
				else if (i0==2) iaddr<=14'h3F01; 
				else if (i0==4) iaddr<=14'h3F80;
				else iaddr<=14'h3F81;		
			end

			else if (zero_index==16637) begin
				if (i0==0) iaddr<=14'h3F7E;
				else if (i0==1) iaddr<=14'h3F7F; 
				else if (i0==3) iaddr<=14'h3FFE;
				else iaddr<=14'h3FFF;		
			end

			else if (zero_index%130==0&&zero_index!=0&&zero_index!=16510) begin
				if (i0==1) iaddr<=addr_index0;
				else if (i0==2) iaddr<=addr_index0+1; 
				else if (i0==4) iaddr<=addr_index0+128;
				else if (i0==5) iaddr<=addr_index0+129;
				else if (i0==7) iaddr<=addr_index0+256;
				else iaddr<=addr_index0+257;
				
			end

			else if (zero_index%130==127&&zero_index!=127&&zero_index!=16637) begin
				if (i5==0) iaddr<=addr_index1;
				else if (i5==1) iaddr<=addr_index1+1; 
				else if (i5==3) iaddr<=addr_index1+128;
				else if (i5==4) iaddr<=addr_index1+129;
				else if (i5==6) iaddr<=addr_index1+256;
				else iaddr<=addr_index1+257;	
			end

			else if (zero_index>0&&zero_index<127) begin
				if (i6==3) iaddr<=addr_index2;
				else if (i6==4) iaddr<=addr_index2+1; 
				else if (i6==5) iaddr<=addr_index2+2;
				else if (i6==6) iaddr<=addr_index2+128;
				else if (i6==7) iaddr<=addr_index2+129;
				else iaddr<=addr_index2+130;	
			end

			else if (zero_index>16510&&zero_index<16637) begin
				if (i4==0) iaddr<=addr_index3;
				else if (i4==1) iaddr<=addr_index3+1; 
				else if (i4==2) iaddr<=addr_index3+2;
				else if (i4==3) iaddr<=addr_index3+128;
				else if (i4==4) iaddr<=addr_index3+129;
				else iaddr<=addr_index3+130;
				
			end

			else begin
				if (i4==0) iaddr<=addr_index4;
				else if (i4==1) iaddr<=addr_index4+1; 
				else if (i4==2) iaddr<=addr_index4+2;
				else if (i4==3) iaddr<=addr_index4+128;
				else if (i4==4) iaddr<=addr_index4+129;
				else if (i4==5) iaddr<=addr_index4+130;
				else if (i4==6) iaddr<=addr_index4+256;
				else if (i4==7) iaddr<=addr_index4+257;
				else iaddr<=addr_index4+258;	
			end
			
		end

		DATA_i0:begin
			if (zero_index==0) begin
				data[0]<=8'h0;
			    data[1]<=8'h0;
			    data[2]<=8'h0;
			    data[3]<=8'h0;
			    data[6]<=8'h0;
                data[i0]<=idata;
			    i0<=(i0==5)?i0+2:i0+1;	
			end
			else if (zero_index==127) begin
				data[0]<=8'h0;
			    data[1]<=8'h0;
			    data[2]<=8'h0;
			    data[5]<=8'h0;
			    data[8]<=8'h0;
                data[i0]<=idata;
			    i0<=(i0==4)?i0+2:i0+1;		
			end

			else if (zero_index==16510) begin
			    data[0]<=8'h0;
			    data[3]<=8'h0;
			    data[6]<=8'h0;
			    data[7]<=8'h0;
			    data[8]<=8'h0;
                data[i0]<=idata;
			    i0<=(i0==2)?i0+2:i0+1;	
			end

			else if (zero_index==16637) begin
				data[2]<=8'h0;
			    data[5]<=8'h0;
			    data[6]<=8'h0;
			    data[7]<=8'h0;
			    data[8]<=8'h0;
                data[i0]<=idata;
			    i0<=(i0==1)?i0+2:i0+1;
			end

			else if (zero_index%130==0&&zero_index!=0&&zero_index!=16510) begin
			   data[0]<=8'h0;
               data[3]<=8'h0;
               data[6]<=8'h0;
               data[i0]<=idata;
               i0<=(i0%3==2)?i0+2:i0+1;	
			end

			else if (zero_index%130==127&&zero_index!=127&&zero_index!=16637) begin
			    data[2]<=8'h0;
			    data[5]<=8'h0;
			    data[8]<=8'h0;
			    data[i5]<=idata;
			    i5<=(i5%3==1)?i5+2:i5+1;
			end

			else if (zero_index>0&&zero_index<127) begin
				data[0]<=8'h0;
                data[1]<=8'h0;
                data[2]<=8'h0;
                data[i6]<=idata;
                i6<=i6+1;
			end

			else if ((zero_index>16510&&zero_index<16637)) begin
				data[6]<=8'h0;
			    data[7]<=8'h0;
			    data[8]<=8'h0;
			    data[i4]<=idata;
			    i4<=i4+1;
			end
			
			else begin
				data[i4]<=idata;
			    i4<=i4+1;
			end	
		end


		LAYER0:begin
			if (i0>=8&&zero_index==0) begin
				i0<=3;
				zero_index<=zero_index+1;
			end

			else if (i0>=7&&zero_index==127) begin
				i0<=1;
				zero_index<=zero_index+3;
			end

			else if (i0>=5&&zero_index==16510) begin
				i0<=0;
				zero_index<=zero_index+1;
			end

			else if (i0>=4&&zero_index==16637) begin
				i0<=0;
				zero_index<=zero_index+1;
				addr_index0<=0;
				addr_index1<=0;
				addr_index2<=0;
				addr_index3<=0;
				addr_index4<=0;
			end

			else if (i0>=8&&zero_index%130==0&&zero_index!=0&&zero_index!=16510) begin
				i0<=0;
				zero_index<=zero_index+1;
				addr_index0<=addr_index0+128;
			end

			else if (i5>=7&&zero_index%130==127&&zero_index!=127&&zero_index!=16637) begin
				i5<=0;
				zero_index<=zero_index+3;
				addr_index1<=addr_index1+128;
			end

			else if (i6>=8&&zero_index>0&&zero_index<127) begin
				i6<=0;
				zero_index<=zero_index+1;
				addr_index2<=addr_index2+1;
			end

			else if (i4>=5&&zero_index>16510&&zero_index<16637) begin
				i4<=0;
				zero_index<=zero_index+1;
				addr_index3<=addr_index3+1;
			end

			else begin
				i4<=0;
				zero_index<=zero_index+1;
				addr_index4<=(addr_index4%128==125)?addr_index4+3:addr_index4+1;
			end
		    ioe<=0;
			wen_L0<=1;
			L0_index<=L0_index+1;
			addr_L0<=L0_index;
            w_data_L0<=($signed(-(data[0]<<1)+data[2]+data[4]+(data[5]<<1)+
                       data[6]+(data[7]<<1)-((data[8]<<1)+data[8]))>0)?$signed(-(data[0]<<1)+data[2]+data[4]+(data[5]<<1)+
                       data[6]+(data[7]<<1)-((data[8]<<1)+data[8])):0;
            
		end

        ADDR2:begin
			fully_flag<=1;
			wen_L0<=0;
			wen_L1<=0;
			oe_L0<=1;
			if(i0==0) addr_L0<=addr_index0;
			else if (i0==1) addr_L0<=addr_index0+1;
			else if (i0==2) addr_L0<=addr_index0+128;
            else addr_L0<=addr_index0+129;			
		end

		LAYER1:begin
			data[i0]<=r_data_L0;
			i0<=i0+1;
		end

		LAYER1_1:begin
			i0<=0;
			addr_index0<=(addr_index0%128==126)?addr_index0+130:addr_index0+2;
            wen_L1<=1;
			oe_L0<=0;
			addr_L1<=addr_index1;
			addr_index1<=addr_index1+1;
			w_data_L1<=(data[0]>=data[1]&&data[0]>=data[2]&&data[0]>=data[3])?data[0]:
			           (data[1]>=data[2]&&data[1]>=data[3]&&data[1]>=data[0])?data[1]:
					   (data[2]>=data[3]&&data[2]>=data[1]&&data[2]>=data[0])?data[2]:
					   (data[3]>=data[0]&&data[3]>=data[2]&&data[3]>=data[1])?data[3]:0;
		end

		ADDR3:begin
			fully_flag<=2;
			wen_L1<=0;
			wen_L2<=0;
			oe_L1<=1;
			oe_weight<=1;
			addr_L1<=addr_index2;
            addr_weight<=addr_index3;
		end

		LAYER2:begin
			data_fully<=$signed(r_data_L1)*r_data_weight+data_fully;
			addr_index2<=addr_index2+1;
			addr_index3<=addr_index3+1;
		end

		LAYER2_1:begin
			addr_index2<=0;
			oe_L1<=0;
			oe_weight<=0;
			wen_L2<=1;
			addr_L2<=addr_index4;
			w_data_L2<=(data_fully>0)?data_fully:data_fully>>>16;
			addr_index4<=addr_index4+1;
			data_fully<=32'b0;
		end

		FINI:begin
			busy<=1;
		end

		default; 
	endcase
end

endmodule
