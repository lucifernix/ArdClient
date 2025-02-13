Haven Resource 1 src �  Peacebreaker.java /* Preprocessed source code */
package haven.res.gfx.terobjs.peacebreaker;

import haven.*;
import haven.render.*;
import java.util.*;

/* >spr: Peacebreaker */
public class Peacebreaker extends Sprite implements Sprite.CUpd {
    public static final Coord3f fstart = Coord3f.o, fend = new Coord3f(0.00f, 0.00f, 18.00f);
    public static final Indir<Resource> pres = Resource.classres(Peacebreaker.class).pool.load("gfx/terobjs/peacebreaker", 1);
    public static final Indir<Resource> sres = Resource.classres(Peacebreaker.class).pool.load("gfx/terobjs/peacebreaker-skull", 1);
    private Sprite pole, flag;
    private float a = 0;
    private final Collection<RenderTree.Slot> slots = new ArrayList<>(1);

    public Peacebreaker(Owner owner, Resource res) {
	super(owner, res);
	pole = Sprite.create(owner, pres.get(), Message.nil);
	flag = Sprite.create(owner, sres.get(), Message.nil);
    }

    public static Peacebreaker mksprite(Owner owner, Resource res, Message sdt) {
	Peacebreaker ret = new Peacebreaker(owner, res);
	ret.update(sdt);
	return(ret);
    }

    public void update(Message sdt) {
	this.a = sdt.eom() ? 0 : sdt.unorm8();
	RUtils.readd(slots, this::parts, () -> {});
    }

    private void parts(RenderTree.Slot slot) {
	slot.add(pole, null);
	Coord3f off = fstart.add(fend.sub(fstart).mul(a));
	slot.add(flag, Location.xlate(off));
    }

    public void added(RenderTree.Slot slot) {
	super.added(slot);
	parts(slot);
	slots.add(slot);
    }

    public void removed(RenderTree.Slot slot) {
	super.removed(slot);
	slots.remove(slot);
    }

    public boolean tick(double dt) {
	pole.tick(dt);
	flag.tick(dt);
	return(super.tick(dt));
    }
}
code   haven.res.gfx.terobjs.peacebreaker.Peacebreaker ����   4 �
 , Y	  Z [
  \	  ]	  ^ _ ` a	 b c
 , d	  e	  f	  g h
  Y
  i
 b j
 b k   q  t
 u v = w	  x	  y
 $ z
 $ {
 $ |
 } ~
 , 
  � � �
 , � � �
 , �	 $ � �A�  
 $ �
  �	  � �
 � � � � � fstart Lhaven/Coord3f; fend pres Lhaven/Indir; 	Signature Lhaven/Indir<Lhaven/Resource;>; sres pole Lhaven/Sprite; flag a F slots Ljava/util/Collection; � Slot InnerClasses 6Ljava/util/Collection<Lhaven/render/RenderTree$Slot;>; <init> � Owner '(Lhaven/Sprite$Owner;Lhaven/Resource;)V Code LineNumberTable mksprite f(Lhaven/Sprite$Owner;Lhaven/Resource;Lhaven/Message;)Lhaven/res/gfx/terobjs/peacebreaker/Peacebreaker; update (Lhaven/Message;)V StackMapTable h � parts !(Lhaven/render/RenderTree$Slot;)V added removed tick (D)Z lambda$update$0 ()V <clinit> 
SourceFile Peacebreaker.java A D 9 : java/util/ArrayList A � ; < 1 2 � � � haven/Resource � � � � � 6 7 5 2 8 7 /haven/res/gfx/terobjs/peacebreaker/Peacebreaker I J � � � � BootstrapMethods � �  O � � U � � � � � � � � . / 0 / � � � � � � � � � P O N O � � � Q O � � R S � / haven/Coord3f A � � � � � gfx/terobjs/peacebreaker � � � gfx/terobjs/peacebreaker-skull haven/Sprite haven/Sprite$CUpd CUpd � haven/render/RenderTree$Slot haven/Sprite$Owner haven/Message (I)V haven/Indir get ()Ljava/lang/Object; nil Lhaven/Message; create C(Lhaven/Sprite$Owner;Lhaven/Resource;Lhaven/Message;)Lhaven/Sprite; eom ()Z unorm8 ()F
 � � (Ljava/lang/Object;)V accept P(Lhaven/res/gfx/terobjs/peacebreaker/Peacebreaker;)Ljava/util/function/Consumer;
  � run ()Ljava/lang/Runnable; haven/RUtils readd J(Ljava/util/Collection;Ljava/util/function/Consumer;Ljava/lang/Runnable;)V add � Node � Op T(Lhaven/render/RenderTree$Node;Lhaven/render/Pipe$Op;)Lhaven/render/RenderTree$Slot; sub  (Lhaven/Coord3f;)Lhaven/Coord3f; mul (F)Lhaven/Coord3f; haven/render/Location xlate ((Lhaven/Coord3f;)Lhaven/render/Location; java/util/Collection (Ljava/lang/Object;)Z remove o (FFF)V classres #(Ljava/lang/Class;)Lhaven/Resource; pool Pool Lhaven/Resource$Pool; haven/Resource$Pool load � Named +(Ljava/lang/String;I)Lhaven/Resource$Named; haven/render/RenderTree � � � T U haven/render/RenderTree$Node � haven/render/Pipe$Op haven/Resource$Named "java/lang/invoke/LambdaMetafactory metafactory � Lookup �(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite; haven/render/Pipe � %java/lang/invoke/MethodHandles$Lookup java/lang/invoke/MethodHandles peacebreaker-full.cjava !  ,  -   . /    0 /    1 2  3    4  5 2  3    4  6 7    8 7    9 :    ; <  3    @ 	  A D  E   p     D*+,� *� *� Y� � *+� �  � � 	� 
� *+� �  � � 	� 
� �    F              -  C  	 G H  E   1     � Y*+� N-,� -�    F        
     I J  E   c     &*+� � � +� � *� *�   �   � �    K    L L�   L M  L F          %   N O  E   W     3+*� �  W� � � � *� � � M+*� ,� �  W�    F       "  # # $ 2 %  P O  E   :     *+� *+� *� +�  W�    F       (  ) 
 *  +  Q O  E   1     *+�  *� +� ! W�    F       .  /  0  R S  E   8     *� '� "W*� '� "W*'� "�    F       3 	 4  5
 T U  E          �    F         V U  E   W      7� #� � $Y%� &� � '� ()� *� � '� (+� *� �    F       	  
 %   l     m  n o p m  r s r W    � ?   B  = � >	 B , C	 - , �	 � � �	 � � �	 �  � 	 �  �	 � � � obst     �  [�\��6:��6:.[�\7codeentry 7   spr haven.res.gfx.terobjs.peacebreaker.Peacebreaker   