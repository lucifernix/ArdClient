Haven Resource 1 src X$  FallingLeaves.java /* Preprocessed source code */
/*
  $use: lib/globfx
  $use: lib/env
*/

package haven.res.lib.leaves;

import haven.*;
import haven.render.*;
import java.util.*;
import java.nio.*;
import haven.res.lib.globfx.*;
import haven.res.lib.env.*;

public class FallingLeaves extends GlobEffect {
    public static final int maxleaves = 10000;
    static final VertexArray.Layout fmt =
	new VertexArray.Layout(new VertexArray.Layout.Input(Homo3D.vertex, new VectorFormat(3, NumberFormat.FLOAT32), 0,  0, 20),
			       new VertexArray.Layout.Input(Homo3D.normal, new VectorFormat(3, NumberFormat.SNORM8),  0, 12, 20),
			       new VertexArray.Layout.Input(Tex2D.texc,    new VectorFormat(2, NumberFormat.UNORM8),  0, 16, 20));

    public final Random rnd = new Random();
    public final Object monitor;
    VertexArray va = null;
    final Leaf leaves[] = new Leaf[maxleaves];
    final Map<Material, MSlot> matmap = new HashMap<Material, MSlot>();
    final Glob glob;
    final Collection<RenderTree.Slot> slots = new ArrayList<>(1);
    int nl;
    float ckt = 0;

    private class MSlot implements Rendered, RenderTree.Node {
	final Material m;
	final Collection<RenderTree.Slot> slots = new ArrayList<>(1);
	Leaf leaves[] = new Leaf[128];
	Model model = null;
	Model.Indices ind = null;
	boolean added = false, update = true;
	int nl;

	MSlot(Material m) {
	    this.m = m;
	}

	public void draw(Pipe state, Render out) {
	    if(model != null)
		out.draw(state, model);
	}

	FillBuffer fillind(Model.Indices dst, Environment env) {
	    FillBuffer ret = env.fillbuf(dst);
	    ByteBuffer buf = ret.push();
	    for(int i = 0; i < nl; i++) {
		Leaf l = leaves[i];
		int vi = l.vidx * 4;
		buf.putShort((short)(vi + 0));
		buf.putShort((short)(vi + 1));
		buf.putShort((short)(vi + 3));
		buf.putShort((short)(vi + 1));
		buf.putShort((short)(vi + 2));
		buf.putShort((short)(vi + 3));
	    }
	    return(ret);
	}

	void update(Render d) {
	    if((model == null) || (model.n != nl * 6)) {
		if(model != null)
		    model.dispose();
		int indsz = (ind == null) ? 0 : ind.n;
		if((indsz < nl * 6) || (indsz > nl * 24))
		    indsz = Math.max(Integer.highestOneBit(nl * 6), 64) << 1;
		if((ind == null) || (indsz != ind.n)) {
		    if(ind != null)
			ind.dispose();
		    ind = new Model.Indices(indsz, NumberFormat.UINT16, DataBuffer.Usage.STREAM, null).shared();
		}
		model = new Model(Model.Mode.TRIANGLES, va, ind, 0, nl * 6);
		for(RenderTree.Slot slot : this.slots)
		    slot.update();
	    }
	    d.update(model.ind, this::fillind);
	}

	void add(Leaf l) {
	    if(nl >= leaves.length)
		leaves = Arrays.copyOf(leaves, leaves.length * 2);
	    (leaves[nl] = l).midx = nl;
	    nl++;
	    update = true;
	}

	void remove(Leaf l) {
	    (leaves[l.midx] = leaves[--nl]).midx = l.midx;
	    leaves[nl] = null;
	    update = true;
	}

	public void added(RenderTree.Slot slot) {
	    slot.ostate(m);
	    slots.add(slot);
	}

	public void removed(RenderTree.Slot slot) {
	    slots.remove(slot);
	}
    }

    public FallingLeaves(Glob glob, Object monitor) {
	this.glob = glob;
	this.monitor = monitor;
    }

    public abstract class Leaf {
	float x, y, z;
	float xv, yv, zv;
	float nx, ny, nz;
	float nxv, nyv, nzv;
	float ar = (0.5f + rnd.nextFloat()) / 50;
	MSlot m;
	int vidx, midx;

	public Leaf(float x, float y, float z) {
	    this.x = x; this.y = y; this.z = z;
	    nx = rnd.nextFloat();
	    ny = rnd.nextFloat();
	    nz = rnd.nextFloat();
	    if(nx < 0.5f) nx -= 1.0f;
	    if(ny < 0.5f) ny -= 1.0f;
	    if(nz < 0.5f) nz -= 1.0f;
	    float nf = 1.0f / (float)Math.sqrt((nx * nx) + (ny * ny) + (nz * nz));
	    nx *= nf;
	    ny *= nf;
	    nz *= nf;
	}

	public Leaf() {
	    this(0, 0, 0);
	}

	public Leaf(Coord3f c) {
	    this(c.x, c.y, c.z);
	}

	public abstract Material mat();
	public float size() {return(1);}
    }

    public static FallingLeaves get(Glob glob) {
	GlobEffector eff = GlobEffector.get(glob);
	return(eff.get(new FallingLeaves(glob, eff.monitor())));
    }

    public void added(RenderTree.Slot slot) {
	for(MSlot mat : matmap.values()) {
	    if(mat.added)
		slot.add(mat);
	}
	slots.add(slot);
    }

    public void removed(RenderTree.Slot slot) {
	slots.remove(slot);
    }

    FillBuffer fillvert(VertexArray.Buffer dst, Environment env) {
	FillBuffer ret = env.fillbuf(dst);
	ByteBuffer buf = ret.push();
	for(int i = 0; i < nl; i++) {
	    try {
		Leaf l = leaves[i];
		byte nx = (byte)(Utils.clip(l.nx, -1, 1) * 127);
		byte ny = (byte)(Utils.clip(l.ny, -1, 1) * 127);
		byte nz = (byte)(Utils.clip(l.nz, -1, 1) * 127);
		float sz = l.size();
		buf.putFloat(l.x + sz * l.nz);
		buf.putFloat(l.y - sz * l.nz);
		buf.putFloat(l.z + sz * (l.ny - l.nx));
		buf.put(nx).put(ny).put(nz).put((byte)0);
		buf.put((byte)0).put((byte)0).put((byte)0).put((byte)0);
		buf.putFloat(l.x + sz * l.nz);
		buf.putFloat(l.y + sz * l.nz);
		buf.putFloat(l.z - sz * (l.nx - l.ny));
		buf.put(nx).put(ny).put(nz).put((byte)0);
		buf.put((byte)0).put((byte)255).put((byte)0).put((byte)0);
		buf.putFloat(l.x - sz * l.nz);
		buf.putFloat(l.y + sz * l.nz);
		buf.putFloat(l.z + sz * (l.nx - l.ny));
		buf.put(nx).put(ny).put(nz).put((byte)0);
		buf.put((byte)255).put((byte)255).put((byte)0).put((byte)0);
		buf.putFloat(l.x - sz * l.nz);
		buf.putFloat(l.y - sz * l.ny);
		buf.putFloat(l.z + sz * (l.nx + l.ny));
		buf.put(nx).put(ny).put(nz).put((byte)0);
		buf.put((byte)255).put((byte)0).put((byte)0).put((byte)0);
	    } catch(RuntimeException exc) {
		throw(new RuntimeException(String.format("%d %d %d", i, buf.position(), buf.capacity()), exc));
	    }
	}
	return(ret);
    }

    void move(float dt) {
	Coord3f av = Environ.get(glob).wind();
	for(int i = 0; i < nl; i++) {
	    Leaf l = leaves[i];
	    float xvd = l.xv - av.x, yvd = l.yv - av.y, zvd = l.zv - av.z;
	    float vel = (float)Math.sqrt((xvd * xvd) + (yvd * yvd) + (zvd * zvd));

	    /* Rotate the normal around the normal velocity vector. */
	    float nvl = (float)Math.sqrt((l.nxv * l.nxv) + (l.nyv * l.nyv) + (l.nzv * l.nzv));
	    if(nvl > 0) {
		float s = (float)Math.sin(nvl * dt);
		float c = (float)Math.cos(nvl * dt);
		nvl = 1.0f / nvl;
		float nxvn = l.nxv * nvl, nyvn = l.nyv * nvl, nzvn = l.nzv * nvl;
		float nx = l.nx, ny = l.ny, nz = l.nz;
		l.nx = (nx * (nxvn * nxvn * (1 - c) + c)) + (ny * (nxvn * nyvn * (1 - c) - nzvn * s)) + (nz * (nxvn * nzvn * (1 - c) + nyvn * s));
		l.ny = (nx * (nyvn * nxvn * (1 - c) + nzvn * s)) + (ny * (nyvn * nyvn * (1 - c) + c)) + (nz * (nyvn * nzvn * (1 - c) - nxvn * s));
		l.nz = (nx * (nzvn * nxvn * (1 - c) - nyvn * s)) + (ny * (nzvn * nyvn * (1 - c) + nxvn * s)) + (nz * (nzvn * nzvn * (1 - c) + c));

		float df = (float)Math.pow(0.7, dt);
		l.nxv *= df;
		l.nyv *= df;
		l.nzv *= df;
	    }

	    /* Add the cross-product of the airspeed and the normal to the normal velocity. */
	    float vr = (vel * vel) / 5.0f, ar = 0.5f;
	    float rxvd = xvd + ((rnd.nextFloat() - 0.5f) * vr), ryvd = yvd + ((rnd.nextFloat() - 0.5f) * vr), rzvd = zvd + ((rnd.nextFloat() - 0.5f) * vr);
	    float nxv = l.nxv, nyv = l.nyv, nzv = l.nzv;
	    l.nxv += (l.ny * rzvd - l.nz * ryvd) * dt * ar;
	    l.nyv += (l.nz * rxvd - l.nx * rzvd) * dt * ar;
	    l.nzv += (l.nx * ryvd - l.ny * rxvd) * dt * ar;

	    float ae = Math.abs((l.nx * xvd) + (l.ny * yvd) + (l.nz * zvd));
	    float xa = (l.nx * ae - xvd), ya = (l.ny * ae - yvd), za = (l.nz * ae - zvd);
	    l.xv += xa * Math.abs(xa) * l.ar * dt;
	    l.yv += ya * Math.abs(ya) * l.ar * dt;
	    l.zv += za * Math.abs(za) * l.ar * dt;
	    l.x += l.xv * dt;
	    l.y += l.yv * dt;
	    l.z += l.zv * dt;
	    l.zv -= 9.81f * dt;
	}
    }

    void ckstop(Glob glob) {
	for(int i = 0; i < nl; i++) {
	    if(leaves[i].vidx != i)
		throw(new AssertionError());
	    boolean drop = false;
	    try {
		drop = leaves[i].z < glob.map.getcz(leaves[i].x, -leaves[i].y) - 1;
	    } catch(Loading e) {
		drop = true;
	    }
	    if(drop) {
		leaves[i].m.remove(leaves[i]);
		(leaves[i] = leaves[--nl]).vidx = i;
		leaves[nl] = null;
		i--;
	    }
	}
    }

    public void gtick(Render d) {
	if(va == null)
	    va = new VertexArray(fmt, new VertexArray.Buffer(maxleaves * 4 * fmt.inputs[0].stride, DataBuffer.Usage.STREAM, null)).shared();
	for(MSlot m : matmap.values()) {
	    if(m.update)
		m.update(d);
	}
	d.update(va.bufs[0], this::fillvert);
    }

    public boolean tick(float dt) {
	for(MSlot m : matmap.values()) {
	    if(!m.added) {
		try {
		    RUtils.multiadd(this.slots, m);
		    m.added = true;
		} catch(Loading l) {
		}
	    }
	}
	if((ckt += dt) > 10) {
	    ckstop(glob);
	    ckt = 0;
	}
	if(nl == 0)
	    return(true);
	move(dt);
	return(false);
    }

    public Coord3f onevertex(Location.Chain loc, FastMesh m) {
	int vi = m.indb.get(rnd.nextInt(m.num));
	VertexBuf.VertexData va = m.vert.buf(VertexBuf.VertexData.class);
	Coord3f vc = new Coord3f(va.data.get(vi * 3),
				 va.data.get(vi * 3 + 1),
				 va.data.get(vi * 3 + 2));
	return(loc.fin(Matrix4f.id).mul4(vc));
    }

    public void addleaf(Leaf leaf) {
	synchronized(monitor) {
	    if(nl >= maxleaves)
		return;
	    (leaves[nl] = leaf).vidx = nl;
	    Material m = leaf.mat();
	    if((leaf.m = matmap.get(m)) == null)
		matmap.put(m, leaf.m = new MSlot(m));
	    leaf.m.add(leaf);
	    nl++;
	}
    }
}
code <  haven.res.lib.leaves.FallingLeaves$MSlot ����   4 �	 0 _
 1 ` a
  b	 0 c e	 0 f	 0 g	 0 h	 0 i	 0 j	 0 k l m n o p q	 0 r	  s
 t u	  v
  w	  v
 x y
 z {
  w |	 } ~	  �
  �
  � �	 � �	 d �
  � � � � � � � � % �	  h   � l �
 � � >	  � % � � � � � � � � � m Lhaven/Material; slots Ljava/util/Collection; 	Signature Slot InnerClasses 6Ljava/util/Collection<Lhaven/render/RenderTree$Slot;>; leaves Leaf *[Lhaven/res/lib/leaves/FallingLeaves$Leaf; model Lhaven/render/Model; ind Indices Lhaven/render/Model$Indices; added Z update nl I this$0 $Lhaven/res/lib/leaves/FallingLeaves; <init> 7(Lhaven/res/lib/leaves/FallingLeaves;Lhaven/Material;)V Code LineNumberTable draw +(Lhaven/render/Pipe;Lhaven/render/Render;)V StackMapTable fillind Q(Lhaven/render/Model$Indices;Lhaven/render/Environment;)Lhaven/render/FillBuffer; � � (Lhaven/render/Render;)V � add ,(Lhaven/res/lib/leaves/FallingLeaves$Leaf;)V remove !(Lhaven/render/RenderTree$Slot;)V removed 
SourceFile FallingLeaves.java I J K � java/util/ArrayList K � 6 7 � 'haven/res/lib/leaves/FallingLeaves$Leaf < > ? @ A C D E F E 4 5 � O � � � � � � � G H � H � � � � H � � � � � � � � haven/render/Model$Indices � � � � � � K � � � haven/render/Model � � � � � K � � � � � � � � � � haven/render/RenderTree$Slot F � BootstrapMethods � � � S � � F � � � � � H � � X � Z � (haven/res/lib/leaves/FallingLeaves$MSlot MSlot java/lang/Object haven/render/Rendered haven/render/RenderTree$Node Node haven/render/FillBuffer java/nio/ByteBuffer java/util/Iterator ()V (I)V "haven/res/lib/leaves/FallingLeaves haven/render/Render *(Lhaven/render/Pipe;Lhaven/render/Model;)V haven/render/Environment fillbuf 4(Lhaven/render/DataBuffer;)Lhaven/render/FillBuffer; push ()Ljava/nio/ByteBuffer; vidx putShort (S)Ljava/nio/ByteBuffer; n dispose java/lang/Integer highestOneBit (I)I java/lang/Math max (II)I haven/render/NumberFormat UINT16 Lhaven/render/NumberFormat; � haven/render/DataBuffer$Usage Usage STREAM Lhaven/render/DataBuffer$Usage; � Filler ^(ILhaven/render/NumberFormat;Lhaven/render/DataBuffer$Usage;Lhaven/render/DataBuffer$Filler;)V shared ()Lhaven/render/Model$Indices; haven/render/Model$Mode Mode 	TRIANGLES Lhaven/render/Model$Mode; va Lhaven/render/VertexArray; T(Lhaven/render/Model$Mode;Lhaven/render/VertexArray;Lhaven/render/Model$Indices;II)V java/util/Collection iterator ()Ljava/util/Iterator; hasNext ()Z next ()Ljava/lang/Object; haven/render/RenderTree
 � � N(Lhaven/render/DataBuffer;Lhaven/render/Environment;)Lhaven/render/FillBuffer;
 0 � fill L(Lhaven/res/lib/leaves/FallingLeaves$MSlot;)Lhaven/render/DataBuffer$Filler; <(Lhaven/render/DataBuffer;Lhaven/render/DataBuffer$Filler;)V java/util/Arrays copyOf )([Ljava/lang/Object;I)[Ljava/lang/Object; midx ostate � Op (Lhaven/render/Pipe$Op;)V (Ljava/lang/Object;)Z haven/render/DataBuffer haven/render/DataBuffer$Filler � � � R S � haven/render/Pipe$Op "java/lang/invoke/LambdaMetafactory metafactory � Lookup �(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite; haven/render/Pipe � %java/lang/invoke/MethodHandles$Lookup java/lang/invoke/MethodHandles leaves.cjava   0 1  2 3 	  4 5    6 7  8    ;   < >     ? @     A C     D E     F E     G H   I J      K L  M   m     9*+� *� *� Y� � * �� � *� *� 	*� 
*� *,� �    N   "    ) 	 "  #  $ $ % ) & 3 * 8 +  O P  M   <     *� � ,+*� �  �    Q     N       .  /  0   R S  M   �     x,+�  N-�  :6*� � ]*� 2:� h6`�� W`�� W`�� W`�� W`�� W`�� W����-�    Q    �  T U� b N   6    3  4  5  6 % 7 . 8 9 9 D : O ; Z < e = p 5 v ?   F V  M  b 	    �*� � *� � *� h� �*� � 
*� � *� 	� � 
*� 	� =*� h� *� h� *� h� @� x=*� 	� *� 	� � '*� 	� 
*� 	� *� Y� � � � � 	*� Y� *� �  *� 	*� h� !� *� � " N-� # � -� $ � %:� & ���+*� � '*� (  � ) �    Q    
F� � * W�  N   >    C  D  E & F 9 G O H a I s J z K � L � N � O � P � R � S   X Y  M   x     C*� *� �� **� *� �h� *� +� *� *� +[S*� � ,*Y� `� *� �    Q    ! N       V  W ! X 3 Y = Z B [   Z Y  M   U     1*� +� ,*� *Y� dZ� 2[S+� ,� ,*� *� S*� �    N       ^ ! _ + ` 0 a  D [  M   6     +*� � - *� +� . W�    N       d 
 e  f  \ [  M   (     *� +� / W�    N   
    i  j  �     �  � � � ]    � :   R 
 % � 9	  d =   B 	 0 d �  3 � �	  � �@ � � �	 �  �@ � � �	 � � � code p  haven.res.lib.leaves.FallingLeaves$Leaf ����   4 \	  <
  =?   	 > ?
 @ ABH  	  B	  C	  D	  E	  F	  G	  H
 I J
  K	 L C	 L D	 L E M O x F y z xv yv zv nx ny nz nxv nyv nzv ar m P MSlot InnerClasses *Lhaven/res/lib/leaves/FallingLeaves$MSlot; vidx I midx this$0 $Lhaven/res/lib/leaves/FallingLeaves; <init> *(Lhaven/res/lib/leaves/FallingLeaves;FFF)V Code LineNumberTable StackMapTable M Q '(Lhaven/res/lib/leaves/FallingLeaves;)V 6(Lhaven/res/lib/leaves/FallingLeaves;Lhaven/Coord3f;)V mat ()Lhaven/Material; size ()F 
SourceFile FallingLeaves.java + , - R Q S T U V 9 "              W X Y - . Z 'haven/res/lib/leaves/FallingLeaves$Leaf Leaf java/lang/Object (haven/res/lib/leaves/FallingLeaves$MSlot "haven/res/lib/leaves/FallingLeaves ()V rnd Ljava/util/Random; java/util/Random 	nextFloat java/lang/Math sqrt (D)D haven/Coord3f leaves.cjava!                                                                           !      "      # '     ( )     * )   + ,     - .  /  8     �*+� *� **� � � bn� *$� *%� 	*� 
*+� � � *+� � � *+� � � *� �� *Y� f� *� �� *Y� f� *� �� *Y� f� *� *� j*� *� jb*� *� jb�� �n8*Y� j� *Y� j� *Y� j� �    1    � b  2 3   0   :    { 	 w  | - } 8 ~ C  N � b � v � � � � � � � � � � �  - 4  /   %     	*+� �    0   
    �  �  - 5  /   .     *+,� ,� ,� � �    0   
    �  � 6 7    8 9  /        �    0       �  :    [ &     $ > %   > Ncode �(  haven.res.lib.leaves.FallingLeaves ����   4 
 � � �
  �	  �	  � � �	  � �
 	 �	  � �
  �	  �	  �	  �	  �
 � �
 � �
  �
 � � � � � � � � � � �	  � � � � � � � � � � �	  �	  ���  
 � �B�  	  �	  �
  �	  �
 � 	 	 
 �

 �	
 �


 .

	 	 o �	 	 o	 	 o
	 	 	 

?�ffffff
@�  ?   
 
	 A��	  
 N �	!"
#$%	 &
 '(	 )*  �@	 {+	 |,	-.
 W/
 U0
 U1	 2
 3	 U4  :;<
=>A   
 ?
 @	AB	AC
 D
EF	AGI
HKL	 mM
NO
 oP	QR
 �S
QT
 U �V
 W �X
 YZ[	]^_	`a
 ~b
 |c	]d	`e	fg	`h
 {ij Leaf InnerClasses MSlot 	maxleaves I ConstantValue  ' fmt Layout !Lhaven/render/VertexArray$Layout; rnd Ljava/util/Random; monitor Ljava/lang/Object; va Lhaven/render/VertexArray; leaves *[Lhaven/res/lib/leaves/FallingLeaves$Leaf; matmap Ljava/util/Map; 	Signature KLjava/util/Map<Lhaven/Material;Lhaven/res/lib/leaves/FallingLeaves$MSlot;>; glob Lhaven/Glob; slots Ljava/util/Collection;l Slot 6Ljava/util/Collection<Lhaven/render/RenderTree$Slot;>; nl ckt F <init> !(Lhaven/Glob;Ljava/lang/Object;)V Code LineNumberTable get 2(Lhaven/Glob;)Lhaven/res/lib/leaves/FallingLeaves; added !(Lhaven/render/RenderTree$Slot;)V StackMapTablem removed fillvert Buffer V(Lhaven/render/VertexArray$Buffer;Lhaven/render/Environment;)Lhaven/render/FillBuffer;no move (F)VL � � ckstop (Lhaven/Glob;)V% gtick (Lhaven/render/Render;)V tick (F)Z � 	onevertexq Chain >(Lhaven/render/Location$Chain;Lhaven/FastMesh;)Lhaven/Coord3f; addleaf ,(Lhaven/res/lib/leaves/FallingLeaves$Leaf;)Vrs <clinit> ()V 
SourceFile FallingLeaves.java � � java/util/Random � � � � "haven/res/lib/leaves/FallingLeaves 'haven/res/lib/leaves/FallingLeaves$Leaf � � java/util/HashMap � � java/util/ArrayList �t � � � � � � � �u �v �w � � �xyz{|}~m��w (haven/res/lib/leaves/FallingLeaves$MSlot �����������n�� � �� ����� �� ���� �o��� �� ��� java/lang/RuntimeException %d %d %d java/lang/Object���������� ��� ����� �� �� ����� �� �� ������������ �� � java/lang/AssertionError������ haven/Loading��� � haven/render/VertexArray � � haven/render/VertexArray$Buffer��� ���� �� ������� ��� BootstrapMethods��� ��������� � � � ����� ���� ����� haven/VertexBuf$VertexData 
VertexData�� haven/Coord3f��� �� ����������� �� ����� � haven/render/VertexArray$Layout %haven/render/VertexArray$Layout$Input Input  haven/render/VectorFormat � �	
 � haven/res/lib/globfx/GlobEffect haven/render/RenderTree$Slot java/util/Iterator haven/render/FillBuffer java/nio/ByteBuffer haven/render/Location$Chain haven/Material java/lang/Throwable (I)V !haven/res/lib/globfx/GlobEffector 1(Lhaven/Glob;)Lhaven/res/lib/globfx/GlobEffector; ()Ljava/lang/Object; <(Lhaven/res/lib/globfx/Effect;)Lhaven/res/lib/globfx/Effect; java/util/Map values ()Ljava/util/Collection; java/util/Collection iterator ()Ljava/util/Iterator; hasNext ()Z next Z add Node >(Lhaven/render/RenderTree$Node;)Lhaven/render/RenderTree$Slot; (Ljava/lang/Object;)Z remove haven/render/Environment fillbuf 4(Lhaven/render/DataBuffer;)Lhaven/render/FillBuffer; push ()Ljava/nio/ByteBuffer; nx haven/Utils clip (FFF)F ny nz size ()F x putFloat (F)Ljava/nio/ByteBuffer; y z put (B)Ljava/nio/ByteBuffer; java/lang/Integer valueOf (I)Ljava/lang/Integer; position ()I capacity java/lang/String format 9(Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/String; *(Ljava/lang/String;Ljava/lang/Throwable;)V haven/res/lib/env/Environ )(Lhaven/Glob;)Lhaven/res/lib/env/Environ; wind ()Lhaven/Coord3f; xv yv zv java/lang/Math sqrt (D)D nxv nyv nzv sin cos pow (DD)D 	nextFloat abs (F)F ar vidx 
haven/Glob map Lhaven/MCache; haven/MCache getcz (FF)F m *Lhaven/res/lib/leaves/FallingLeaves$MSlot; inputs ([Lhaven/render/VertexArray$Layout$Input; stride haven/render/DataBuffer$Usage Usage STREAM Lhaven/render/DataBuffer$Usage; Filler C(ILhaven/render/DataBuffer$Usage;Lhaven/render/DataBuffer$Filler;)V F(Lhaven/render/VertexArray$Layout;[Lhaven/render/VertexArray$Buffer;)V shared ()Lhaven/render/VertexArray; update bufs "[Lhaven/render/VertexArray$Buffer;
 N(Lhaven/render/DataBuffer;Lhaven/render/Environment;)Lhaven/render/FillBuffer;
  fill F(Lhaven/res/lib/leaves/FallingLeaves;)Lhaven/render/DataBuffer$Filler; haven/render/Render <(Lhaven/render/DataBuffer;Lhaven/render/DataBuffer$Filler;)V haven/RUtils multiadd L(Ljava/util/Collection;Lhaven/render/RenderTree$Node;)Ljava/util/Collection; haven/FastMesh indb Ljava/nio/ShortBuffer; num nextInt (I)I java/nio/ShortBuffer (I)S vert Lhaven/VertexBuf; haven/VertexBuf buf 
AttribData /(Ljava/lang/Class;)Lhaven/VertexBuf$AttribData; data Ljava/nio/FloatBuffer; java/nio/FloatBuffer (I)F (FFF)V haven/Matrix4f id Lhaven/Matrix4f; fin "(Lhaven/Matrix4f;)Lhaven/Matrix4f; mul4  (Lhaven/Coord3f;)Lhaven/Coord3f; mat ()Lhaven/Material; &(Ljava/lang/Object;)Ljava/lang/Object; 7(Lhaven/res/lib/leaves/FallingLeaves;Lhaven/Material;)V 8(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object; haven/render/Homo3D vertex Lhaven/render/sl/Attribute; haven/render/NumberFormat FLOAT32 Lhaven/render/NumberFormat; (ILhaven/render/NumberFormat;)V <(Lhaven/render/sl/Attribute;Lhaven/render/VectorFormat;III)V normal SNORM8 haven/render/Tex2D texc UNORM8 +([Lhaven/render/VertexArray$Layout$Input;)V haven/render/RenderTree haven/render/Location haven/render/RenderTree$Node haven/render/DataBuffer haven/render/DataBuffer$Filler � � haven/VertexBuf$AttribData "java/lang/invoke/LambdaMetafactory metafactory Lookup �(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite; %java/lang/invoke/MethodHandles$Lookup java/lang/invoke/MethodHandles leaves.cjava !  �     � �  �    �  � �    � �    � �     � �    � �    � �  �    �  � �    � �  �    �   � �     � �     � �  �   �     E*� *� Y� � *� *'� � *� 	Y� 
� *� Y� � *� *+� *,� �    �   * 
   m         )  5  : n ? o D p 	 � �  �   5     *� L+� Y*+� � � � �    �   
    �  �  � �  �   ~     @*� �  �  M,�  � ,�  � N-� � +-�  W���*� +�  W�    �    �  �!�  �       � " � ) � 1 � 4 � ? �  � �  �   (     *� +�  W�    �   
    �  �   � �  �      L,+�  N-�   :6*� !�1*� 2:� "#� $%j��6� &#� $%j��6� '#� $%j��6	� (8
� )
� 'jb� *W� +
� 'jf� *W� ,
� &� "fjb� *W� -� -	� -� -W� -� -� -� -W� )
� 'jb� *W� +
� 'jb� *W� ,
� "� &fjf� *W� -� -	� -� -W� -� -� -� -W� )
� 'jf� *W� +
� 'jb� *W� ,
� "� &fjb� *W� -� -	� -� -W� -� -� -� -W� )
� 'jf� *W� +
� &jf� *W� ,
� "� &bjb� *W� -� -	� -� -W� -� -� -� -W� 6:� .Y/� 0Y� 1SY� 2� 1SY� 3� 1S� 4� 5�����-�   .  �    �  � ��� �2�  �   � !   �  �  �  � % � 7 � I � [ � b � v � � � � � � � � � � � � � �% �8 �L �` �z �� �� �� �� �� �� � � � �D �J �   � �  �  ,    T*� � 6� 7M>*� !�A*� 2:� 8,� 9f8� :,� ;f8� <,� =f8jjbjb�� >�8� ?� ?j� @� @jb� A� Ajb�� >�8		��8	#j�� B�8
	#j�� C�8	n8	� ?	j8� @	j8� A	j8� "8� &8� '8jfjbjjfj
jfjbjfj
jbjb� "jfj
jbjjfjbjbjfj
jfjb� &jfj
jfjjfj
jbjbjfjbjb� ' D#�� F�8Y� ?j� ?Y� @j� @Y� Aj� AjGn8
H8*� � IHf
jb8*� � IHf
jb8*� � IHf
jb8� ?8� @8� A8Y� ?� &j� 'jf#jjb� ?Y� @� 'j� "jf#jjb� @Y� A� "j� &jf#jjb� A� "j� &jb� 'jb� J8� "jf8� &jf8� 'jf8Y� 8� Jj� Kj#jb� 8Y� :� Jj� Kj#jb� :Y� <� Jj� Kj#jb� <Y� )� 8#jb� )Y� +� :#jb� +Y� ,� <#jb� ,Y� <L#jf� <�����    �   . �  ��� 
 � � �  ��  � �   �   � $   �  �  �  � A � Y � � � � � � � � � � � � � � � �S �� �� �� �� �� �� � � �8 �X �x �� �� �� �� � � �. �? �M �S �   � �  �       �=*� !� �*� 2� M� � NY� O�>*� 2� ,+� P*� 2� )*� 2� +v� Qf�� � >� :>� =*� 2� S*� 2� T*� *� *Y� !dZ� !2[S� M*� *� !S�����j�  ! P S R  �    � � .@C �� =�  �   >    � 
 �  �  � ! � P S � U  W [ m � � � � �	  � �  �   �     *� � 4*� UY� V� WY� WYX� V� Y2� Zh� [� \S� ]� ^� *� �  �  M,�  � ,�  � N-� _� -+� `���+*� � a2*� b  � c �    �    8�  ��  �   "     8 Z a f i ~  � �  �   �     m*� �  �  M,�  � *,�  � N-� � *� -� dW-� � :���*Y� #bZ� e�� **� � f*� *� !� �*#� g�  ) 7 : R  �   $ �  �� *  � � �  �� �  �   :    " ) 2 7 : < ? P  X! ]# d$ f% k&  � �  �   �     \,� h*� ,� i� j� k>,� lm� n� m:� oY� ph� q� ph`� q� ph`� q� r:+� s� t� u�    �      * + !, :- G. O/  � �  �   �     x*� YM�*� !'� ,ñ*� *� !+[S*� !� M+� vN+*� -� w � Z� S� *� -+� Y*-� xZ� S� y W+� S+� z*Y� !`� !,ç 
:,���    p    m p   p t p    �   $ �  �� D ��   � � �  ��  �   .   3 4 5 6 &7 +8 @9 Y: a; k< w=  � �  �   }      e� {Y� |Y� |Y� }� ~Y� � �� �SY� |Y� �� ~Y� �� �� �SY� |Y� �� ~Y� �� �� �S� �� V�    �        5    6 789 �    �   j    �   �  { U � 	 �k �	 W U � 	 �p � 	 mHJ 	 | {\ 	�k�	-��@���	�H�	 codeentry    lib/globfx  lib/env   