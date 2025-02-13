Haven Resource 1 src   Rope.java /* Preprocessed source code */
package haven.res.gfx.fx.hangrope;

import java.util.*;
import haven.*;
import haven.render.*;
import static haven.render.VertexArray.Layout;
import static haven.render.RenderTree.Slot;

public class Rope implements RenderTree.Node, Rendered {
    public static final Layout fmt  = new Layout(new Layout.Input(Homo3D.vertex, new VectorFormat(3, NumberFormat.FLOAT32), 0, 0, 24),
						 new Layout.Input(Homo3D.normal, new VectorFormat(3, NumberFormat.FLOAT32), 0, 12, 24));
    public final Coord3f off;
    public final float z1, z2, d;
    public final Model model;
    public final Collection<Slot> slots = new ArrayList<>(1);

    public Rope(Coord3f off, float z1, float z2) {
	off = Coord3f.of(off.x, -off.y, off.z);
	this.off = off;
	this.z1 = z1;
	this.z2 = z2;
	this.d = (float)Math.hypot(off.x, off.y);
	this.model = mkmodel();
    }

    public Model mkmodel() {
	int n = Math.max(1 + Math.round(d / 3), 3);
	VertexBuilder buf = new VertexBuilder(fmt);
	buf.set(1, 0, 0, 1);
	for(int i = 0; i < n; i++) {
	    float a = (float)i / (float)(n - 1);
	    buf.set(0, getc(a));
	    buf.emit();
	}
	return(new Model(Model.Mode.LINE_STRIP, buf.finv(), null));
    }

    public Coord3f getc(float a) {
	return(Coord3f.of(off.x * a, off.y * a, ((off.z + z2 - z1) * a) + z1 - ((float)Math.cos((a - 0.5) * Math.PI) * d * 0.1f)));
    }

    public void draw(Pipe st, Render g) {
	g.draw(st, model);
    }

    public void added(Slot slot) {slots.add(slot);}
    public void removed(Slot slot) {slots.remove(slot);}
}

src 2  RopeClick.java /* Preprocessed source code */
package haven.res.gfx.fx.hangrope;

import java.util.*;
import haven.*;
import haven.render.*;
import static haven.render.VertexArray.Layout;
import static haven.render.RenderTree.Slot;

public class RopeClick extends Clickable {
    public final Gob gob;
    public final int part;

    public RopeClick(Gob gob, int part) {
	this.gob = gob;
	this.part = part;
    }

    public Object[] clickargs(ClickData cd) {
	Object[] ret = {0, (int)gob.id, gob.rc.floor(OCache.posres), 0, part};
	for(Object node : cd.array()) {
	    if(node instanceof Gob.Overlay) {
		ret[0] = 1;
		ret[3] = ((Gob.Overlay)node).id;
	    }
	}
	return(ret);
    }

    public String toString() {
	return(String.format("#<gob-click %d %s>", gob.id, gob.getres()));
    }
}

/* >spr: HangingRope */
src �  HangingRope.java /* Preprocessed source code */
package haven.res.gfx.fx.hangrope;

import java.util.*;
import haven.*;
import haven.render.*;
import static haven.render.VertexArray.Layout;
import static haven.render.RenderTree.Slot;

public class HangingRope extends Sprite {
    public static final Pipe.Op ropemat = Pipe.Op.compose(Location.goback("gobx"), Rendered.postpfx, new States.LineWidth(UI.scale(3)),
							  new Light.PhongLight(true, new FColor(0.3f, 0.2f, 0.15f)));
    public final long end;
    public final Collection<Sprite> hanging;
    private final Gob gob;
    private Rope rope = null;
    private Hanging hangc = null;
    private final Collection<Slot> slots = new ArrayList<>(1);

    public HangingRope(Owner owner, Resource res, long end, Collection<Sprite> hanging) {
	super(owner, res);
	this.gob = (owner instanceof Gob) ? (Gob)owner : owner.context(Gob.class);
	this.end = end;
	this.hanging = hanging;
    }

    public static HangingRope mksprite(Owner owner, Resource res, Message sdt) {
	long end = sdt.uint32();
	ArrayList<Sprite> hanging = new ArrayList<>();
	while(!sdt.eom()) {
	    Resource hres = owner.context(Resource.Resolver.class).getres(sdt.uint16()).get();
	    Message hdt = new MessageBuf(sdt.bytes(sdt.uint8()));
	    hanging.add(Sprite.create(owner, hres, hdt));
	}
	hanging.trimToSize();
	return(new HangingRope(owner, res, end, hanging));
    }

    public class Hanging implements RenderTree.Node {
	public final Collection<Slot> slots = new ArrayList<>(1);
	public final RenderTree.Node[] parts;

	public Hanging() {
	    Collection<RenderTree.Node> posd = new ArrayList<>();
	    int i = 0, n = hanging.size();
	    for(Sprite h : hanging) {
		posd.add(Pipe.Op.compose(Location.xlate(rope.getc((float)(i + 1) / (float)(n + 1))),
					 h.res.flayer(Skeleton.BoneOffset.class, "h").from(null).get(),
					 new RopeClick(gob, i))
			 .apply(h, false));
		i++;
	    }
	    parts = posd.toArray(new RenderTree.Node[0]);
	}

	public void added(Slot slot) {
	    slot.ostate(Location.goback("gobx"));
	    for(RenderTree.Node part : parts)
		slot.add(part);
	    slots.add(slot);
	}
	public void removed(Slot slot) {
	    slots.remove(slot);
	}
    }

    private Gob curend = null;
    public boolean tick(double dt) {
	Gob end = gob.glob.oc.getgob(this.end);
	if(end != curend) {
	    if(rope != null) {
		while(!rope.slots.isEmpty())
		    Utils.el(rope.slots).remove();
		rope = null;
	    }
	    if(hangc != null) {
		while(!hangc.slots.isEmpty())
		    Utils.el(hangc.slots).remove();
		hangc = null;
	    }
	    curend = end;
	}
	if((end != null) && (rope == null)) {
	    try {
		Rope rope = new Rope(end.getc().sub(gob.getc()), 25, 25);
		RUtils.multiadd(slots, ropemat.apply(rope, false));
		this.rope = rope;
	    } catch (Loading l) {
	    }
	}
	if((rope != null) && (hangc == null)) {
	    Hanging hangc = new Hanging();
	    try {
		RUtils.multiadd(slots, hangc);
		this.hangc = hangc;
	    } catch(Loading l) {
	    }
	}
	for(Sprite h : hanging)
	    h.tick(dt);
	return(false);
    }

    public void added(Slot slot) {
	slot.ostate(new RopeClick(gob, -1));
	if(rope != null)
	    slot.add(ropemat.apply(rope.model, false));
	if(hangc != null)
	    slot.add(hangc);
	slots.add(slot);
    }

    public void removed(Slot slot) {
	slots.remove(slot);
    }
}
code h  haven.res.gfx.fx.hangrope.Rope ����   4 �
 2 Z [
  \	 1 ]	 ^ _	 ^ `	 ^ a
 ^ b	 1 c	 1 d	 1 e
   f	 1 g
 1 h	 1 i@@  
   j
   k l	 1 m
  n
  o
 1 p
  q
  r s	 t u
  v
  w?�       x@	!�TD-
   y=��� z { | } | ~ � �	 � � �	 � �
 + �
 ) �	 � �
 ( � � � � � fmt Layout InnerClasses !Lhaven/render/VertexArray$Layout; off Lhaven/Coord3f; z1 F z2 d model Lhaven/render/Model; slots Ljava/util/Collection; 	Signature � Slot 6Ljava/util/Collection<Lhaven/render/RenderTree$Slot;>; <init> (Lhaven/Coord3f;FF)V Code LineNumberTable mkmodel ()Lhaven/render/Model; StackMapTable l getc (F)Lhaven/Coord3f; draw +(Lhaven/render/Pipe;Lhaven/render/Render;)V added !(Lhaven/render/RenderTree$Slot;)V removed <clinit> ()V 
SourceFile 	Rope.java G W java/util/ArrayList G � A B � � < � < � < � � 9 : ; < = < � � > < K L ? @ � � � � haven/VertexBuilder 5 8 G � � � O P � � � � haven/render/Model � � � � � G � java/lang/Math � � � Q � � � � � � � haven/render/VertexArray$Layout %haven/render/VertexArray$Layout$Input Input � � � haven/render/VectorFormat � � � G � G � � � G � haven/res/gfx/fx/hangrope/Rope java/lang/Object � haven/render/RenderTree$Node Node haven/render/Rendered haven/render/RenderTree$Slot (I)V haven/Coord3f x y z of (FFF)Lhaven/Coord3f; hypot (DD)D round (F)I max (II)I $(Lhaven/render/VertexArray$Layout;)V set (I[F)Lhaven/VertexBuilder; '(ILhaven/Coord3f;)Lhaven/VertexBuilder; emit ()I haven/render/Model$Mode Mode 
LINE_STRIP Lhaven/render/Model$Mode; finv ()Lhaven/render/VertexArray; � Indices R(Lhaven/render/Model$Mode;Lhaven/render/VertexArray;Lhaven/render/Model$Indices;)V cos (D)D haven/render/Render *(Lhaven/render/Pipe;Lhaven/render/Model;)V java/util/Collection add (Ljava/lang/Object;)Z remove haven/render/VertexArray haven/render/Homo3D vertex Lhaven/render/sl/Attribute; haven/render/NumberFormat FLOAT32 Lhaven/render/NumberFormat; (ILhaven/render/NumberFormat;)V <(Lhaven/render/sl/Attribute;Lhaven/render/VectorFormat;III)V normal +([Lhaven/render/VertexArray$Layout$Input;)V haven/render/RenderTree haven/render/Model$Indices hangrope.cjava ! 1 2  3 4   5 8    9 :    ; <    = <    > <    ? @    A B  C    F   G H  I   �     K*� *� Y� � +� +� v+� � L*+� 	*$� 
*%� *+� �+� �� �� **� � �    J   & 	        !  &  +  0  B  J   K L  I   �     h*� n� `� <� Y� � M,�YQYQYQ� W>� #�d�n8,*� � W,� W���޻ Y� ,� � �    M    � 3 N� $ J   & 	        1  8  A   M ! R  X #  O P  I   ]     E*� 	� #j*� 	� #j*� 	� *� b*� 
f#j*� 
b#� g !k� #�*� j$jf� �    J       '  Q R  I   (     ,+*� � % �    J   
    +  ,  S T  I   $     *� +� & W�    J       .  U T  I   $     *� +� ' W�    J       /  V W  I   `      H� (Y� )Y� )Y� *� +Y� ,� -� .SY� )Y� /� +Y� ,� -� .S� 0� �    J       
  X    � 7   2  (  6 	 D � E	 ) ( � 	 3 � �	 t  �@ �  � 	code �  haven.res.gfx.fx.hangrope.RopeClick ����   4 Z
  %	  &	  ' (
 ) *	 + ,	 + -	 . /
 0 1
 2 3 4	  7 8
 9 :
 + ;
 < = > ? gob Lhaven/Gob; part I <init> (Lhaven/Gob;I)V Code LineNumberTable 	clickargs &(Lhaven/ClickData;)[Ljava/lang/Object; StackMapTable > @ A toString ()Ljava/lang/String; 
SourceFile RopeClick.java  B     java/lang/Object C D E F G H I J K L J M N O @ P Q haven/Gob$Overlay Overlay InnerClasses G  #<gob-click %d %s> R D S T U V W X #haven/res/gfx/fx/hangrope/RopeClick haven/Clickable haven/ClickData [Ljava/lang/Object; ()V java/lang/Integer valueOf (I)Ljava/lang/Integer; 	haven/Gob id J rc Lhaven/Coord2d; haven/OCache posres haven/Coord2d floor (Lhaven/Coord2d;)Lhaven/Coord; array ()[Ljava/lang/Object; java/lang/Long (J)Ljava/lang/Long; getres ()Lhaven/Resource; java/lang/String format 9(Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/String; hangrope.cjava !                        3     *� *+� *� �           6  7 	 8  9        �     y� Y� SY*� � �� SY*� � � � 	SY� SY*� � SM+� 
N-�66� ,-2:� � ,� S,� � � S����,�        � G         )�         < ; = T > \ ? c @ q = w C  ! "     9     !� Y*� � � SY*� � S� �           G  #    Y 6   
   + 5 	code �  haven.res.gfx.fx.hangrope.HangingRope$Hanging ����   4 �	 & B
 ' C D
  E	 & F
  C	 G H I J I K L M L N O Q
 G S
 T U
 V W	  X Z \
 ] ^
  _ ` a b
 G c
  d  e  f I g i I j 1	 & k l
 V m + n + o I p q s slots Ljava/util/Collection; 	Signature t Slot InnerClasses 6Ljava/util/Collection<Lhaven/render/RenderTree$Slot;>; parts Node [Lhaven/render/RenderTree$Node; this$0 'Lhaven/res/gfx/fx/hangrope/HangingRope; <init> *(Lhaven/res/gfx/fx/hangrope/HangingRope;)V Code LineNumberTable StackMapTable q u v w added !(Lhaven/render/RenderTree$Slot;)V removed 
SourceFile HangingRope.java 2 3 4 x java/util/ArrayList 4 y ( ) u z ) v { | } ~ w  � � � haven/Sprite � haven/render/Pipe$Op Op � � � � � � � � � � � haven/Skeleton$BoneOffset 
BoneOffset h � � � � � � � � #haven/res/gfx/fx/hangrope/RopeClick � � 4 � � � � � � � � haven/render/RenderTree$Node � � / 1 gobx � � � � � � � � -haven/res/gfx/fx/hangrope/HangingRope$Hanging Hanging java/lang/Object haven/render/RenderTree$Slot %haven/res/gfx/fx/hangrope/HangingRope java/util/Collection java/util/Iterator ()V (I)V hanging size ()I iterator ()Ljava/util/Iterator; hasNext ()Z next ()Ljava/lang/Object; haven/render/Pipe 
access$000 I(Lhaven/res/gfx/fx/hangrope/HangingRope;)Lhaven/res/gfx/fx/hangrope/Rope; haven/res/gfx/fx/hangrope/Rope getc (F)Lhaven/Coord3f; haven/render/Location xlate ((Lhaven/Coord3f;)Lhaven/render/Location; res Lhaven/Resource; haven/Skeleton haven/Resource flayer � IDLayer =(Ljava/lang/Class;Ljava/lang/Object;)Lhaven/Resource$IDLayer; from 2(Lhaven/EquipTarget;)Ljava/util/function/Supplier; java/util/function/Supplier get 
access$100 4(Lhaven/res/gfx/fx/hangrope/HangingRope;)Lhaven/Gob; (Lhaven/Gob;I)V compose /([Lhaven/render/Pipe$Op;)Lhaven/render/Pipe$Op; apply � Wrapping @(Lhaven/render/RenderTree$Node;Z)Lhaven/render/Pipe$Op$Wrapping; add (Ljava/lang/Object;)Z haven/render/RenderTree toArray (([Ljava/lang/Object;)[Ljava/lang/Object; goback *(Ljava/lang/String;)Lhaven/render/Pipe$Op; ostate (Lhaven/render/Pipe$Op;)V >(Lhaven/render/RenderTree$Node;)Lhaven/render/RenderTree$Slot; remove haven/Resource$IDLayer haven/render/Pipe$Op$Wrapping hangrope.cjava ! & '     ( )  *    .  / 1   2 3     4 5  6  -     �*+� *� *� Y� � � Y� M>+� �  6+� � 	 :� 
 � o�  � :,� Y+� `�`�n� � SY� � � � �  � SY� Y+� � S� �  �  W����*,� �  � �  �    8    � 5  9 : ; <  � u 7   >    m 	 j  n  o * p K q r r � s � q � t � q � u � v � w � x  = >  6   |     =+!� "� # *�  M,�>6� ,2:+� $ W����*� +�  W�    8    �  �  7       {  | " } + | 1 ~ <   ? >  6   (     *� +� % W�    7   
    �  �  @    � -   :  + h ,	  h 0	  P R	  Y [ 	 & G r  � ] �	 �  � 	code �  haven.res.gfx.fx.hangrope.HangingRope ����   43	  �	  �
 5 �	  � �
  �	  �	  � � c �	  �	  �
 � �
  �
 � � �
 � �  � � � � �
 � �
 � �
  �
 5 �
  �
  � �
  �	 	 �	 � �
 � �	 ' � � �
 � � � $ �	 0 � �
 	 �
 � �A�  
 ' �	  � > �
 � � � �
 0 � � � � � � � �
 5 � �
 7 � $ �	 ' � $ � � � � � � �
 � �	 � � �
 � �
 B � � �>���>L��>��
 F �
 E � > � Hanging InnerClasses ropemat Op Lhaven/render/Pipe$Op; end J hanging Ljava/util/Collection; 	Signature &Ljava/util/Collection<Lhaven/Sprite;>; gob Lhaven/Gob; rope  Lhaven/res/gfx/fx/hangrope/Rope; hangc /Lhaven/res/gfx/fx/hangrope/HangingRope$Hanging; slots Slot 6Ljava/util/Collection<Lhaven/render/RenderTree$Slot;>; curend <init> � Owner >(Lhaven/Sprite$Owner;Lhaven/Resource;JLjava/util/Collection;)V Code LineNumberTable StackMapTable � � � � � N(Lhaven/Sprite$Owner;Lhaven/Resource;JLjava/util/Collection<Lhaven/Sprite;>;)V mksprite \(Lhaven/Sprite$Owner;Lhaven/Resource;Lhaven/Message;)Lhaven/res/gfx/fx/hangrope/HangingRope; � tick (D)Z � � � added !(Lhaven/render/RenderTree$Slot;)V removed 
access$000 I(Lhaven/res/gfx/fx/hangrope/HangingRope;)Lhaven/res/gfx/fx/hangrope/Rope; 
access$100 4(Lhaven/res/gfx/fx/hangrope/HangingRope;)Lhaven/Gob; <clinit> ()V 
SourceFile HangingRope.java X Y Z [ b � \ ] java/util/ArrayList b � ^ U a Y 	haven/Gob � � R S T U � � � b  � � haven/Resource$Resolver Resolver � � � � � � � haven/Resource haven/MessageBuf � � � � b � � � � � �  %haven/res/gfx/fx/hangrope/HangingRope b e � � � � � � � � � � � � �  haven/render/RenderTree$Slot  haven/res/gfx/fx/hangrope/Rope b O Q	 haven/Loading -haven/res/gfx/fx/hangrope/HangingRope$Hanging b � � � haven/Sprite r s #haven/res/gfx/fx/hangrope/RopeClick b � � haven/render/Pipe$Op gobx !"%& haven/render/States$LineWidth 	LineWidth'()* haven/Light$PhongLight 
PhongLight haven/FColor b+ b,-. haven/Sprite$Owner java/util/Collection java/util/Iterator '(Lhaven/Sprite$Owner;Lhaven/Resource;)V (I)V context %(Ljava/lang/Class;)Ljava/lang/Object; haven/Message uint32 ()J eom ()Z uint16 ()I getres (I)Lhaven/Indir; haven/Indir get ()Ljava/lang/Object; uint8 bytes (I)[B ([B)V create C(Lhaven/Sprite$Owner;Lhaven/Resource;Lhaven/Message;)Lhaven/Sprite; add (Ljava/lang/Object;)Z 
trimToSize glob Lhaven/Glob; 
haven/Glob oc Lhaven/OCache; haven/OCache getgob (J)Lhaven/Gob; isEmpty haven/Utils el ((Ljava/lang/Iterable;)Ljava/lang/Object; haven/render/RenderTree remove getc ()Lhaven/Coord3f; haven/Coord3f sub  (Lhaven/Coord3f;)Lhaven/Coord3f; (Lhaven/Coord3f;FF)V apply/ Node0 Wrapping @(Lhaven/render/RenderTree$Node;Z)Lhaven/render/Pipe$Op$Wrapping; haven/RUtils multiadd L(Ljava/util/Collection;Lhaven/render/RenderTree$Node;)Ljava/util/Collection; *(Lhaven/res/gfx/fx/hangrope/HangingRope;)V iterator ()Ljava/util/Iterator; hasNext next (Lhaven/Gob;I)V ostate (Lhaven/render/Pipe$Op;)V model Lhaven/render/Model; >(Lhaven/render/RenderTree$Node;)Lhaven/render/RenderTree$Slot; haven/render/Pipe haven/render/Location goback *(Ljava/lang/String;)Lhaven/render/Pipe$Op; haven/render/Rendered postpfx1 Order Lhaven/render/Rendered$Order; haven/render/States haven/UI scale (I)I haven/Light (FFF)V (ZLhaven/FColor;)V compose /([Lhaven/render/Pipe$Op;)Lhaven/render/Pipe$Op; haven/render/RenderTree$Node haven/render/Pipe$Op$Wrapping haven/render/Rendered$Order hangrope.cjava !  5     O Q    R S    T U  V    W  X Y    Z [    \ ]    ^ U  V    `  a Y     b e  f   �     J*+,� *� *� *� Y� � *� *+� 	� 
+� 	� +	� 
 � 	� *!� *� �    h   3 � 0  i j k l  i� 
  i j k l  i m g   & 	   W  R  S  T  � ! X > Y C Z I [ V    n 	 o p  f   �     g,� B� Y� :,� � C*� 
 � ,� �  �  � :� Y,,� � � :*� � W���� � Y*+!� �    h    �  q� F g   & 	   ^  _  `  a 3 b D c R d U e Z f  r s  f  �    *� � � *� �  N-*� � h*� � ,*� � !� " � *� � !� #� $� % ���*� *� � ,*� � &� " � *� � &� #� $� % ���*� *-� -� C*� � <� 'Y-� (*� � (� )**� +:*� � ,� - � .W*� � :*� � )*� � "� 0Y*� 1:*� � .W*� � :*� � 2 :� 3 � � 4 � 5:'� 6W����  � � � / � � � /  h   5 � ! m##� A t� *  i m u  t� � 
 v�  g   j    �  �  � ! � 0 � E � J � Q � ` � u � z �  � � � � � � � � � � � � � � � � � � � � � � � � � � �  w x  f   �     N+� 7Y*� � 8� 9 *� � +� ,*� � :� - � ; W*� � +*� � ; W*� +� < W�    h    0 g       �  �  � 0 � 7 � B � M �  y x  f   (     *� +� = W�    g   
    �  � z {  f        *� �    g       L | }  f        *� �    g       L  ~   f   W      ?� >Y?� @SY� ASY� BY� C� DSY� EY� FYGHI� J� KS� L� ,�    g       M  �   2 N   R 
 0  M  > � P	 $ � _	 c 5 d	   �	 B � � 	 E � � 	
 �	 > 	# �$	codeentry -   spr haven.res.gfx.fx.hangrope.HangingRope   