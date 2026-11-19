#include "include/system_theme/system_theme_plugin.h"
#include "accent_color.h"

#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

static constexpr char kPortalName[] = "org.freedesktop.portal.Desktop";
static constexpr char kPortalPath[] = "/org/freedesktop/portal/desktop";
static constexpr char kPortalSettingsInterface[] =
	"org.freedesktop.portal.Settings";
static constexpr char kXdgAppearanceNamespace[] = "org.freedesktop.appearance";
static constexpr char kGnomeDesktopInterfaceSchema[] =
	"org.gnome.desktop.interface";
static constexpr char kAccentColorKey[] = "accent-color";
static constexpr gint kPortalCallTimeoutMs = 2000;

#define SYSTEM_THEME_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), system_theme_plugin_get_type(), \
                              SystemThemePlugin))

struct _SystemThemePlugin {
	GObject parent_instance;
	FlPluginRegistrar *registrar;
	FlEventChannel *event_channel;
	GDBusProxy *portal_proxy;
	gboolean portal_proxy_initialized;
	gulong portal_signal_handler_id;
	GSettings *gnome_settings;
	gboolean gnome_settings_initialized;
	gulong gnome_settings_handler_id;
	gboolean is_listening;
	GWeakRef observed_widget;
	gulong style_updated_handler_id;
	SystemThemeColorState color_state;
};

G_DEFINE_TYPE(SystemThemePlugin, system_theme_plugin, g_object_get_type())


static bool ensure_portal_proxy(SystemThemePlugin *self) {
	if (!self->portal_proxy_initialized) {
		self->portal_proxy_initialized = TRUE;
		self->portal_proxy = g_dbus_proxy_new_for_bus_sync(
				G_BUS_TYPE_SESSION,
				G_DBUS_PROXY_FLAGS_DO_NOT_LOAD_PROPERTIES,
				nullptr,
				kPortalName,
				kPortalPath,
				kPortalSettingsInterface,
				nullptr,
				nullptr);
	}
	return self->portal_proxy != nullptr;
}

static bool ensure_gnome_settings(SystemThemePlugin *self) {
	if (!self->gnome_settings_initialized) {
		self->gnome_settings_initialized = TRUE;
		GSettingsSchemaSource *source = g_settings_schema_source_get_default();
		if (source != nullptr) {
			g_autoptr(GSettingsSchema) schema =
					g_settings_schema_source_lookup(
							source, kGnomeDesktopInterfaceSchema, TRUE);
			if (schema != nullptr &&
				g_settings_schema_has_key(schema, kAccentColorKey)) {
				self->gnome_settings =
						g_settings_new_full(schema, nullptr, nullptr);
			}
		}
	}
	return self->gnome_settings != nullptr;
}

static bool extract_portal_accent_color(GVariant *variant,
                                        SystemThemeColor *color) {
	if (variant == nullptr || color == nullptr) {
		return false;
	}

	g_autoptr(GVariant) current = g_variant_ref(variant);
	if (g_variant_is_of_type(current, G_VARIANT_TYPE("(v)"))) {
		GVariant *child = g_variant_get_child_value(current, 0);
		g_variant_unref(current);
		current = child;
	}

	while (g_variant_is_of_type(current, G_VARIANT_TYPE_VARIANT)) {
		GVariant *inner = g_variant_get_variant(current);
		g_variant_unref(current);
		current = inner;
	}

	if (!g_variant_is_of_type(current, G_VARIANT_TYPE("(ddd)"))) {
		return false;
	}

	double red = 0.0;
	double green = 0.0;
	double blue = 0.0;
	g_variant_get(current, "(ddd)", &red, &green, &blue);
	return system_theme_portal_rgb_to_color(red, green, blue, color);
}

static GVariant *call_portal_settings_method(GDBusProxy *proxy,
                                             const gchar *method_name,
                                             GError **error) {
	return g_dbus_proxy_call_sync(
			proxy,
			method_name,
			g_variant_new("(ss)", kXdgAppearanceNamespace, kAccentColorKey),
			G_DBUS_CALL_FLAGS_NONE,
			kPortalCallTimeoutMs,
			nullptr,
			error);
}

static bool lookup_portal_accent_color(SystemThemePlugin *self,
                                       SystemThemeColor *color) {
	if (!ensure_portal_proxy(self)) {
		return false;
	}

	g_autoptr(GError) error = nullptr;
	g_autoptr(GVariant) value =
			call_portal_settings_method(self->portal_proxy, "ReadOne", &error);
	if (value == nullptr &&
		g_error_matches(error, G_DBUS_ERROR, G_DBUS_ERROR_UNKNOWN_METHOD)) {
		g_clear_error(&error);
		value = call_portal_settings_method(self->portal_proxy, "Read", &error);
	}

	if (value == nullptr) {
		return false;
	}

	return extract_portal_accent_color(value, color);
}

static bool lookup_gnome_accent_color(SystemThemePlugin *self,
                                      SystemThemeColor *color) {
	if (!ensure_gnome_settings(self)) {
		return false;
	}

	g_autofree gchar *name =
			g_settings_get_string(self->gnome_settings, kAccentColorKey);
	return system_theme_gnome_accent_name_to_color(name, color);
}

static bool lookup_gtk_accent_color(SystemThemePlugin *self,
                                    SystemThemeColor *color) {
	if (self->registrar == nullptr || color == nullptr) {
		return false;
	}

	FlView *view = fl_plugin_registrar_get_view(self->registrar);
	if (view == nullptr) {
		return false;
	}

	GtkWidget *widget = GTK_WIDGET(view);
	GtkStyleContext *context = gtk_widget_get_style_context(widget);
	if (context == nullptr) {
		return false;
	}

	GdkRGBA accent_color = {};
	return system_theme_rgba_to_color(
			gtk_style_context_lookup_color(
				context, "theme_selected_bg_color", &accent_color),
			accent_color.red, accent_color.green, accent_color.blue,
			accent_color.alpha, color);
}

static bool lookup_fallback_accent_color(SystemThemePlugin *self,
                                         SystemThemeColor *color) {
	return lookup_gnome_accent_color(self, color) ||
		   lookup_gtk_accent_color(self, color);
}

static bool lookup_accent_color(SystemThemePlugin *self,
                                SystemThemeColor *color) {
	return lookup_portal_accent_color(self, color) ||
		   lookup_fallback_accent_color(self, color);
}

static FlValue *color_to_fl_value_map(const SystemThemeColor &color) {
	FlValue *map = fl_value_new_map();
	fl_value_set_string_take(map, "R", fl_value_new_int(color.red));
	fl_value_set_string_take(map, "G", fl_value_new_int(color.green));
	fl_value_set_string_take(map, "B", fl_value_new_int(color.blue));
	fl_value_set_string_take(map, "A", fl_value_new_int(color.alpha));

	FlValue *colors = fl_value_new_map();
	fl_value_set_string_take(colors, "accent", map);
	return colors;
}

static void emit_color_if_changed(SystemThemePlugin *self,
                                  bool found,
                                  const SystemThemeColor &color) {
	if (!self->is_listening || self->event_channel == nullptr) {
		return;
	}
	if (!system_theme_color_state_update(&self->color_state, found, color)) {
		return;
	}

	g_autoptr(FlValue) colors = color_to_fl_value_map(color);
	g_autoptr(GError) error = nullptr;
	if (!fl_event_channel_send(self->event_channel, colors, nullptr, &error)) {
		g_warning("Failed to send system theme change event: %s",
				  error != nullptr ? error->message : "unknown error");
	}
}

static void disconnect_signal_if_connected(gpointer instance,
                                           gulong *handler_id) {
	if (instance != nullptr && *handler_id != 0 &&
		g_signal_handler_is_connected(instance, *handler_id)) {
		g_signal_handler_disconnect(instance, *handler_id);
	}
	*handler_id = 0;
}

static void stop_listening(SystemThemePlugin *self) {
	self->is_listening = FALSE;

	disconnect_signal_if_connected(self->portal_proxy,
								   &self->portal_signal_handler_id);
	disconnect_signal_if_connected(self->gnome_settings,
								   &self->gnome_settings_handler_id);

	g_autoptr(GObject) widget =
			static_cast<GObject *>(g_weak_ref_get(&self->observed_widget));
	disconnect_signal_if_connected(widget, &self->style_updated_handler_id);

	g_weak_ref_set(&self->observed_widget, nullptr);
	system_theme_color_state_reset(&self->color_state);
}

static void portal_signal_cb(GDBusProxy *proxy,
                             const gchar *sender_name,
                             const gchar *signal_name,
                             GVariant *parameters,
                             gpointer user_data) {
	SystemThemePlugin *self = SYSTEM_THEME_PLUGIN(user_data);
	if (g_strcmp0(signal_name, "SettingChanged") != 0 ||
		parameters == nullptr ||
		!g_variant_is_of_type(parameters, G_VARIANT_TYPE("(ssv)"))) {
		return;
	}

	const gchar *ns = nullptr;
	const gchar *key = nullptr;
	g_autoptr(GVariant) value = nullptr;
	g_variant_get(parameters, "(&s&sv)", &ns, &key, &value);
	if (g_strcmp0(ns, kXdgAppearanceNamespace) != 0 ||
		g_strcmp0(key, kAccentColorKey) != 0) {
		return;
	}

	SystemThemeColor color = {};
	bool found = extract_portal_accent_color(value, &color) ||
				 lookup_fallback_accent_color(self, &color);
	emit_color_if_changed(self, found, color);
}

static void gnome_accent_changed_cb(GSettings *settings,
                                    const gchar *key,
                                    gpointer user_data) {
	SystemThemePlugin *self = SYSTEM_THEME_PLUGIN(user_data);
	SystemThemeColor color = {};
	bool found = lookup_accent_color(self, &color);
	emit_color_if_changed(self, found, color);
}

static void style_updated_cb(GtkWidget *widget, gpointer user_data) {
	SystemThemePlugin *self = SYSTEM_THEME_PLUGIN(user_data);
	SystemThemeColor color = {};
	bool found = lookup_accent_color(self, &color);
	emit_color_if_changed(self, found, color);
}

static FlMethodErrorResponse *listen_cb(FlEventChannel *channel,
										FlValue *args,
										gpointer user_data) {
	SystemThemePlugin *self = SYSTEM_THEME_PLUGIN(user_data);
	stop_listening(self);
	self->is_listening = TRUE;

	if (ensure_portal_proxy(self)) {
		self->portal_signal_handler_id = g_signal_connect_object(
				self->portal_proxy, "g-signal",
				G_CALLBACK(portal_signal_cb), self,
				static_cast<GConnectFlags>(0));
	}

	if (ensure_gnome_settings(self)) {
		self->gnome_settings_handler_id = g_signal_connect_object(
				self->gnome_settings, "changed::accent-color",
				G_CALLBACK(gnome_accent_changed_cb), self,
				static_cast<GConnectFlags>(0));
		g_autofree gchar *armed =
				g_settings_get_string(self->gnome_settings, kAccentColorKey);
		(void)armed;
	}

	FlView *view = self->registrar != nullptr
					   ? fl_plugin_registrar_get_view(self->registrar)
					   : nullptr;
	if (view != nullptr) {
		GtkWidget *widget = GTK_WIDGET(view);
		g_weak_ref_set(&self->observed_widget, widget);
		self->style_updated_handler_id = g_signal_connect_object(
				widget, "style-updated", G_CALLBACK(style_updated_cb), self,
				static_cast<GConnectFlags>(0));
	}

	SystemThemeColor current_color = {};
	bool found = lookup_accent_color(self, &current_color);
	system_theme_color_state_update(&self->color_state, found, current_color);

	return nullptr;
}

static FlMethodErrorResponse *cancel_cb(FlEventChannel *channel,
										FlValue *args,
										gpointer user_data) {
	SystemThemePlugin *self = SYSTEM_THEME_PLUGIN(user_data);
	stop_listening(self);
	return nullptr;
}


// Called when a method call is received from Flutter.
static void system_theme_plugin_handle_method_call(
		SystemThemePlugin *self,
		FlMethodCall *method_call) {
	g_autoptr(FlMethodResponse) response = nullptr;

	const gchar *method = fl_method_call_get_name(method_call);

	if (strcmp(method, "SystemTheme.accentColor") == 0) {
		SystemThemeColor color = {};
		if (!lookup_accent_color(self, &color)) {
			response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
		} else {
			g_autoptr(FlValue) colors = color_to_fl_value_map(color);
			response = FL_METHOD_RESPONSE(fl_method_success_response_new(colors));
		}

	} else {
		response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
	}


	fl_method_call_respond(method_call, response, nullptr);
}

static void system_theme_plugin_dispose(GObject *object) {
	SystemThemePlugin *self = SYSTEM_THEME_PLUGIN(object);
	stop_listening(self);
	g_clear_object(&self->portal_proxy);
	self->portal_proxy_initialized = FALSE;
	g_clear_object(&self->gnome_settings);
	self->gnome_settings_initialized = FALSE;
	g_clear_object(&self->event_channel);
	g_clear_object(&self->registrar);

	G_OBJECT_CLASS(system_theme_plugin_parent_class)->dispose(object);
}

static void system_theme_plugin_finalize(GObject *object) {
	SystemThemePlugin *self = SYSTEM_THEME_PLUGIN(object);
	g_weak_ref_clear(&self->observed_widget);

	G_OBJECT_CLASS(system_theme_plugin_parent_class)->finalize(object);
}

static void system_theme_plugin_class_init(SystemThemePluginClass *klass) {
	GObjectClass *object_class = G_OBJECT_CLASS(klass);
	object_class->dispose = system_theme_plugin_dispose;
	object_class->finalize = system_theme_plugin_finalize;
}

static void system_theme_plugin_init(SystemThemePlugin *self) {
	self->registrar = nullptr;
	self->event_channel = nullptr;
	self->portal_proxy = nullptr;
	self->portal_proxy_initialized = FALSE;
	self->portal_signal_handler_id = 0;
	self->gnome_settings = nullptr;
	self->gnome_settings_initialized = FALSE;
	self->gnome_settings_handler_id = 0;
	self->is_listening = FALSE;
	g_weak_ref_init(&self->observed_widget, nullptr);
	self->style_updated_handler_id = 0;
	system_theme_color_state_reset(&self->color_state);
}

static void method_call_cb(FlMethodChannel *channel, FlMethodCall *method_call,
						   gpointer user_data) {
	SystemThemePlugin *plugin = SYSTEM_THEME_PLUGIN(user_data);
	system_theme_plugin_handle_method_call(plugin, method_call);
}

void system_theme_plugin_register_with_registrar(FlPluginRegistrar *registrar) {
	SystemThemePlugin *plugin = SYSTEM_THEME_PLUGIN(
			g_object_new(system_theme_plugin_get_type(), nullptr));
	plugin->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));

	g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
	g_autoptr(FlMethodChannel) channel =
			fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
								  "system_theme",
								  FL_METHOD_CODEC(codec));
	fl_method_channel_set_method_call_handler(channel, method_call_cb,
											  g_object_ref(plugin),
											  g_object_unref);

	plugin->event_channel = fl_event_channel_new(
			fl_plugin_registrar_get_messenger(registrar),
			"system_theme_events/switch_callback",
			FL_METHOD_CODEC(codec));
	fl_event_channel_set_stream_handlers(plugin->event_channel,
										 listen_cb,
										 cancel_cb,
										 g_object_ref(plugin),
										 g_object_unref);

	g_object_unref(plugin);
}
